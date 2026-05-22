import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  static const _storageKey = 'supabase_session';
  final _secureStorage = const FlutterSecureStorage();

  const SecureLocalStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return await _secureStorage.containsKey(key: _storageKey);
  }

  @override
  Future<String?> accessToken() async {
    return await _secureStorage.read(key: _storageKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _secureStorage.write(key: _storageKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    await _secureStorage.delete(key: _storageKey);
  }

  // Directly access storage for other tokens if needed
  Future<void> write(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
