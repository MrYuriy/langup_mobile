import 'package:flutter/foundation.dart';

/// Runtime configuration for the app (API endpoints, OAuth client id).
///
/// Override the API base at build/run time with:
///   flutter run --dart-define=API_BASE_URL=https://langup.piatek-magazyn.com/api
class AppConfig {
  AppConfig._();

  /// Explicit override wins if provided.
  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Base URL of the backend API (everything lives under `/api`).
  ///
  /// Defaults per target when no --dart-define is given:
  ///  - Android emulator: 10.0.2.2 is the host machine's localhost.
  ///  - Web/desktop dev:  plain localhost.
  /// For a physical phone on the same Wi-Fi, pass the PC's LAN IP via
  /// `--dart-define=API_BASE_URL=http://<lan-ip>:8000/api`
  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  static const String productionApiBaseUrl =
      'https://langup.piatek-magazyn.com/api';

  /// Google Web OAuth client id (same one the web cabinet uses). On mobile it is
  /// passed to google_sign_in as `serverClientId` so the backend can verify the
  /// returned id_token. Native Android/iOS client ids are configured in the
  /// platform projects (google-services.json / Info.plist) separately.
  static const String googleServerClientId =
      '471613816800-9smmatdn665mn85tivimn9dh1iegto76.apps.googleusercontent.com';
}
