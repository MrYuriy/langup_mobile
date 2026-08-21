import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/models/user.dart';
import '../../core/token_store.dart';
import 'auth_repository.dart';

enum AuthStatus {
  /// Startup: tokens not yet checked. The router shows a splash.
  unknown,
  unauthenticated,

  /// Signed in but must pick a native language before entering the cabinet.
  needsLanguage,
  authenticated,
}

class AuthState {
  const AuthState({required this.status, this.user});

  final AuthStatus status;
  final User? user;

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  AuthState withUser(User user) => AuthState(
        status: user.needsLanguage
            ? AuthStatus.needsLanguage
            : AuthStatus.authenticated,
        user: user,
      );
}

/// Owns the session lifecycle and drives the router's redirects.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._api, this._tokens)
      : super(const AuthState.unknown()) {
    // A refresh that can't be recovered drops us straight to the login screen.
    _api.onSessionExpired = () =>
        state = const AuthState(status: AuthStatus.unauthenticated);
  }

  final AuthRepository _repo;
  final ApiClient _api;
  final TokenStore _tokens;

  /// Called once on launch: restore tokens and validate the session.
  Future<void> bootstrap() async {
    await _tokens.load();
    if (!_tokens.hasSession) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repo.me();
      state = state.withUser(user);
    } catch (_) {
      await _tokens.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async =>
      state = state.withUser(await _repo.login(email, password));

  Future<void> register(String email, String password, String? name) async =>
      state = state.withUser(await _repo.register(email, password, name));

  Future<void> setNativeLanguage(String language) async {
    final id = state.user?.id;
    if (id == null) return;
    state = state.withUser(await _repo.setNativeLanguage(id, language));
  }

  Future<void> forgotPassword(String email) => _repo.forgotPassword(email);

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
