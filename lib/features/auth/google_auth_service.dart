import 'package:flutter/foundation.dart';
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

  /// Static, not per-instance: [GoogleSignIn.instance] is a singleton whose
  /// `initialize()` may run only once per page load — a second call throws
  /// StateError. Widgets build this service freely (the web sign-in button
  /// makes its own), so the memo has to be shared by every instance.
  static Future<void>? _init;

  /// True only once initialization has actually SUCCEEDED — see [signOut].
  static bool _ready = false;

  /// Shared by the mobile flow and the web button, so both configure the SDK
  /// the same way.
  ///
  /// The parameter differs by platform and is not interchangeable: the web
  /// plugin asserts serverClientId is null and wants the same Web client id as
  /// `clientId`, while on Android/iOS it is `serverClientId` that makes Google
  /// mint an id_token whose audience the backend accepts.
  Future<void> ensureInitialized() {
    return _init ??= _signIn
        .initialize(
          clientId: kIsWeb ? AppConfig.googleServerClientId : null,
          serverClientId: kIsWeb ? null : AppConfig.googleServerClientId,
        )
        .then((_) {
      _ready = true;
    });
  }

  /// Runs the interactive Google sign-in and returns the id_token.
  /// Returns `null` if the user cancels. Throws [AuthException] otherwise.
  ///
  /// Web does not come through here: a browser will not open the account
  /// chooser from arbitrary code, so the plugin refuses `authenticate()` and
  /// requires Google's own rendered button instead — see GoogleSignInButton.
  Future<String?> signIn() async {
    if (!_signIn.supportsAuthenticate()) {
      throw AuthException(
        'Google Sign-In is not supported on this platform build yet.',
      );
    }
    await ensureInitialized();
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

  /// Best-effort sign-out of the Google SDK.
  ///
  /// Guarded by [_ready] because on web the plugin's `signOut()` starts with
  /// `await _initialized` — a Completer that ONLY a finished `init()` ever
  /// completes. Called before that, it returns a Future that never completes:
  /// not an error a catch can see, just a permanent hang. The timeout covers
  /// the remaining case, an init that started but never finished (the GIS
  /// script failed to load).
  Future<void> signOut() async {
    if (!_ready) return;
    try {
      await _signIn.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best-effort; the app already cleared its own session.
    }
  }
}
