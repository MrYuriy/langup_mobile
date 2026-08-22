import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/models/user.dart';
import '../../core/token_store.dart';
import 'auth_repository.dart';
import 'google_auth_service.dart';

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
  AuthController(this._repo, this._api, this._tokens, this._google)
      : super(const AuthState.unknown()) {
    // A refresh that can't be recovered drops us straight to the login screen.
    _api.onSessionExpired = () =>
        state = const AuthState(status: AuthStatus.unauthenticated);
  }

  final AuthRepository _repo;
  final ApiClient _api;
  final TokenStore _tokens;
  final GoogleAuthService _google;

  /// Called once on launch: restore the session without forcing a re-login.
  ///
  /// A stored refresh token means the user is signed in. We try to freshen the
  /// profile, but a network failure must NOT log them out — only a refresh the
  /// server actually rejected does (the interceptor clears the tokens then).
  Future<void> bootstrap() async {
    await _tokens.load();
    if (!_tokens.hasSession) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    final cached = _tokens.cachedUser;
    try {
      await _apply(await _repo.me());
    } catch (_) {
      if (!_tokens.hasSession) {
        // The interceptor found the session genuinely invalid and cleared it.
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else if (cached != null) {
        // Transient/offline: keep the session, show the cached profile.
        state = state.withUser(User.fromJson(cached));
      } else {
        // Tokens are valid but we have no cached profile and can't reach the
        // server. Don't bounce to login — enter the app; screens refresh later.
        state = const AuthState(status: AuthStatus.authenticated);
      }
    }
  }

  /// Persist the profile alongside the tokens and update state.
  Future<void> _apply(User user) async {
    await _tokens.saveUser(user.toJson());
    state = state.withUser(user);
  }

  Future<void> login(String email, String password) async =>
      _apply(await _repo.login(email, password));

  Future<void> register(String email, String password, String? name) async =>
      _apply(await _repo.register(email, password, name));

  /// Interactive Google sign-in. Does nothing if the user cancels.
  Future<void> signInWithGoogle() async {
    final idToken = await _google.signIn();
    if (idToken == null) return; // canceled
    await _apply(await _repo.googleLogin(idToken));
  }

  /// Re-send the confirmation email; returns true if a new one was sent
  /// (false when the address is already verified).
  Future<bool> resendVerification() => _repo.resendVerification();

  /// Re-fetch the profile (e.g. after the user confirms their email elsewhere).
  Future<void> refreshUser() async {
    try {
      await _apply(await _repo.me());
    } catch (_) {
      // Leave the current state; a hard 401 already routes via onSessionExpired.
    }
  }

  Future<void> setNativeLanguage(String language) async {
    final id = state.user?.id;
    if (id == null) return;
    await _apply(await _repo.setNativeLanguage(id, language));
  }

  Future<void> forgotPassword(String email) => _repo.forgotPassword(email);

  Future<void> updateProfile({
    required String? fullName,
    required String? nativeLanguage,
    required String? targetLanguage,
  }) async {
    final id = state.user?.id;
    if (id == null) return;
    final user = await _repo.updateProfile(
      id,
      fullName: fullName,
      nativeLanguage: nativeLanguage,
      targetLanguage: targetLanguage,
    );
    await _apply(user);
  }

  Future<void> logout() async {
    await _repo.logout();
    await _google.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> logoutEverywhere() async {
    try {
      await _repo.logoutEverywhere();
    } catch (_) {
      // Fall through to a local logout regardless.
    }
    await logout();
  }
}
