import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config.dart';
import 'auth_repository.dart';

/// Wraps google_sign_in (v7) to obtain a Google **id_token**, which the backend
/// verifies at `POST /auth/google`.
///
/// `serverClientId` is the backend's Web OAuth client id; passing it here makes
/// Google mint an id_token whose audience the server accepts. On Android this
/// also requires an **Android OAuth client** registered in the same Google Cloud
/// project keyed by this app's package name + signing SHA-1 (see README).
class GoogleAuthService {
  GoogleAuthService([GoogleSignIn? signIn])
      : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  Future<void>? _init;

  Future<void> _ensureInitialized() {
    return _init ??= _signIn.initialize(
      serverClientId: AppConfig.googleServerClientId,
    );
  }

  /// Runs the interactive Google sign-in and returns the id_token.
  /// Returns `null` if the user cancels. Throws [AuthException] otherwise.
  Future<String?> signIn() async {
    if (!_signIn.supportsAuthenticate()) {
      throw AuthException(
        'Google Sign-In is not supported on this platform build yet.',
      );
    }
    await _ensureInitialized();
    try {
      final account = await _signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthException('Google did not return an id token.');
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthException('Google Sign-In failed: ${e.code.name}');
    }
  }

  Future<void> signOut() async {
    try {
      await _signIn.signOut();
    } catch (_) {
      // Best-effort; the app already cleared its own session.
    }
  }
}
