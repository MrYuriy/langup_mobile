import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/models/token_pair.dart';
import '../../core/models/user.dart';
import '../../core/token_store.dart';

/// Thin wrapper over the backend `/auth` + `/users` endpoints. Persists the
/// token pair on every successful sign-in.
class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  Dio get _dio => _api.dio;

  Future<User> login(String email, String password) async {
    final resp = await _dio.post('/auth/login',
        data: {'email': email, 'password': password});
    _ensureOk(resp, fallback: 'Invalid email or password');
    await _store(TokenPair.fromJson(_asMap(resp.data)));
    return me();
  }

  Future<User> register(String email, String password, String? fullName) async {
    final resp = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
    });
    _ensureOk(resp, fallback: 'Could not sign up');
    await _store(TokenPair.fromJson(_asMap(resp.data)));
    return me();
  }

  Future<User> googleLogin(String idToken) async {
    final resp = await _dio.post('/auth/google', data: {'id_token': idToken});
    _ensureOk(resp, fallback: 'Could not sign in with Google');
    await _store(TokenPair.fromJson(_asMap(resp.data)));
    return me();
  }

  Future<void> forgotPassword(String email) async {
    // Always succeeds from the caller's view — no account enumeration.
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<User> me() async {
    final resp = await _dio.get('/auth/me');
    _ensureOk(resp, fallback: 'Session expired');
    return User.fromJson(_asMap(resp.data));
  }

  Future<User> setNativeLanguage(int userId, String language) async {
    final resp = await _dio
        .patch('/users/$userId', data: {'native_language': language});
    _ensureOk(resp, fallback: 'Could not save the language');
    return User.fromJson(_asMap(resp.data));
  }

  Future<void> logout() async {
    final refresh = _tokens.refresh;
    await _tokens.clear();
    if (refresh == null || refresh.isEmpty) return;
    try {
      await _dio.post('/auth/logout', data: {'refresh_token': refresh});
    } on DioException {
      // Already signed out locally; nothing useful to do.
    }
  }

  Future<void> _store(TokenPair pair) => _tokens.save(
        access: pair.accessToken,
        refresh: pair.refreshToken,
      );

  Map<String, dynamic> _asMap(Object? data) =>
      (data as Map).cast<String, dynamic>();

  /// Raise a readable [AuthException] on a non-2xx response.
  void _ensureOk(Response resp, {required String fallback}) {
    final code = resp.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    throw AuthException(_message(resp.data, fallback));
  }

  /// Pull a message out of a FastAPI error body: a plain `detail` string, or the
  /// first message of a 422 validation list (e.g. weak password).
  String _message(Object? body, String fallback) {
    if (body is Map) {
      final detail = body['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty && detail.first is Map) {
        final msg = (detail.first as Map)['msg'];
        if (msg is String) return msg.replaceFirst('Value error, ', '');
      }
    }
    return fallback;
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
