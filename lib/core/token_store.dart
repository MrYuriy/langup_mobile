import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT access + rotating refresh tokens in the platform secure
/// store (Keychain on iOS, EncryptedSharedPreferences/Keystore on Android),
/// replacing the web cabinet's localStorage.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'langup_access';
  static const _kRefresh = 'langup_refresh';
  static const _kUser = 'langup_user';

  // In-memory mirror so the interceptor reads tokens without awaiting disk.
  String? _access;
  String? _refresh;
  Map<String, dynamic>? _user;
  bool _loaded = false;

  String? get access => _access;
  String? get refresh => _refresh;
  bool get hasSession => (_refresh?.isNotEmpty ?? false);

  /// The last profile we saw, cached so the app can show the signed-in shell on
  /// launch even before (or without) a network round-trip.
  Map<String, dynamic>? get cachedUser => _user;

  /// Load the persisted tokens once at startup.
  Future<void> load() async {
    if (_loaded) return;
    _access = await _storage.read(key: _kAccess);
    _refresh = await _storage.read(key: _kRefresh);
    final rawUser = await _storage.read(key: _kUser);
    if (rawUser != null) {
      try {
        _user = jsonDecode(rawUser) as Map<String, dynamic>;
      } catch (_) {
        _user = null;
      }
    }
    _loaded = true;
  }

  Future<void> save({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    _user = user;
    await _storage.write(key: _kUser, value: jsonEncode(user));
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _user = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
  }
}
