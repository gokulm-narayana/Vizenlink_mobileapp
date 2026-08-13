import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Android-Keystore/iOS-Keychain-backed storage for camera passwords, keyed by camera id.
///
/// `HomesController` persists everything else about a camera (identity/connection fields) in
/// plain `SharedPreferences` — see `_persistedCameraJson`'s doc — but the password is secret and
/// must not sit in plaintext on disk, so it's kept separately here instead.
class CameraCredentialsStore {
  CameraCredentialsStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String _keyFor(String cameraId) => 'camera_password_$cameraId';

  Future<String?> readPassword(String cameraId) {
    return _storage.read(key: _keyFor(cameraId));
  }

  Future<void> savePassword(String cameraId, String? password) {
    if (password == null) return deletePassword(cameraId);
    return _storage.write(key: _keyFor(cameraId), value: password);
  }

  Future<void> deletePassword(String cameraId) {
    return _storage.delete(key: _keyFor(cameraId));
  }
}
