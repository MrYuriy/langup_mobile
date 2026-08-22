import 'package:dio/dio.dart';

import 'config.dart';
import 'token_store.dart';

/// Result of trying to refresh the access token.
enum RefreshOutcome {
  /// New tokens obtained and stored.
  refreshed,

  /// The server rejected the refresh token (expired/reused) — the session is
  /// genuinely over, so log out.
  invalid,

  /// A transient failure (no network, timeout, server 5xx). The tokens are
  /// still good; keep the session and let a later request retry.
  networkError,
}

/// Central HTTP client.
///
/// Mirrors the web cabinet's `api.js`: every request carries the Bearer access
/// token, and a 401 triggers a single refresh + retry. Refresh tokens ROTATE on
/// the server — each one is single-use and replaying a spent token is treated as
/// theft and kills every session — so two concurrent 401s must never each fire
/// their own refresh. All of them await one shared refresh call (single-flight).
class ApiClient {
  ApiClient(this.tokens) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
        // Callers read most 4xx bodies themselves (403 email-not-verified, 404
        // empty pool), so those must NOT throw. But 401 MUST throw — that is the
        // only signal that routes into onError, where the token is refreshed and
        // the request retried. Accepting 401 as a normal response (the old bug)
        // meant refresh never ran and every call failed once the access token
        // expired ("Invalid or expired token").
        validateStatus: (s) => s != null && s < 500 && s != 401,
      ),
    );
    // A bare Dio with no interceptors, used only to refresh — so the refresh
    // call itself can never recurse back into the 401 handler.
    _refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final access = tokens.access;
          if (access != null && access.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final response = error.response;
          final path = error.requestOptions.path;
          final canRetry = error.requestOptions.extra['__retried'] != true;

          if (response?.statusCode == 401 &&
              canRetry &&
              tokens.hasSession &&
              !_isAuthEndpoint(path)) {
            final outcome = await _refreshOnce();
            if (outcome == RefreshOutcome.refreshed) {
              try {
                final opts = error.requestOptions;
                opts.extra['__retried'] = true;
                opts.headers['Authorization'] = 'Bearer ${tokens.access}';
                final retry = await dio.fetch(opts);
                return handler.resolve(retry);
              } catch (e) {
                if (e is DioException) return handler.next(e);
                rethrow;
              }
            }
            // Only log out when the server actually rejected the refresh token.
            // A network blip keeps the session — the user stays signed in and
            // the next request retries once connectivity is back.
            if (outcome == RefreshOutcome.invalid) {
              await tokens.clear();
              onSessionExpired?.call();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final TokenStore tokens;
  late final Dio dio;
  late final Dio _refreshDio;

  /// Called when a refresh fails and the session can't be recovered; the app
  /// wires this to route back to the login screen.
  void Function()? onSessionExpired;

  // Shared in-flight refresh so concurrent 401s coalesce into one call.
  Future<RefreshOutcome>? _refreshing;

  Future<RefreshOutcome> _refreshOnce() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<RefreshOutcome> _doRefresh() async {
    final token = tokens.refresh;
    if (token == null || token.isEmpty) return RefreshOutcome.invalid;
    try {
      final resp = await _refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': token},
        // Accept up to 5xx so we can tell "server rejected the token" (4xx)
        // apart from "server had a hiccup" (5xx) — the latter keeps the session.
        options: Options(validateStatus: (s) => s != null),
      );
      final code = resp.statusCode ?? 0;
      if (code == 200 && resp.data is Map) {
        final data = resp.data as Map;
        await tokens.save(
          access: data['access_token'] as String,
          refresh: data['refresh_token'] as String,
        );
        return RefreshOutcome.refreshed;
      }
      // 401/403 (and other 4xx) mean the refresh token is no good — log out.
      // 5xx is a server problem, not an invalid session — keep the tokens.
      if (code >= 400 && code < 500) return RefreshOutcome.invalid;
      return RefreshOutcome.networkError;
    } on DioException {
      // No network / timeout: keep the tokens so a later request can retry.
      return RefreshOutcome.networkError;
    }
  }

  static bool _isAuthEndpoint(String path) {
    const unauthed = [
      '/auth/login',
      '/auth/register',
      '/auth/google',
      '/auth/refresh',
      '/auth/forgot-password',
      '/auth/reset-password',
    ];
    return unauthed.any(path.contains);
  }
}
