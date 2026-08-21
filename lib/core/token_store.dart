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

  // In-memory mirror so the interceptor reads tokens without awaiting disk.
  String? _access;
  String? _refresh;
  bool _loaded = false;

  String? get access => _access;
  String? get refresh => _refresh;
  bool get hasSession => (_refresh?.isNotEmpty ?? false);

  /// Load the persisted tokens once at startup.
  Future<void> load() async {
    if (_loaded) return;
    _access = await _storage.read(key: _kAccess);
    _refresh = await _storage.read(key: _kRefresh);
    _loaded = true;
  }

  Future<void> save({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
