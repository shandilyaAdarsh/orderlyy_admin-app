// ── Local Storage Service ────────────────────────────────────────────────────
// Provides persistent storage for serializable state.
// Used for offline-first architecture and state hydration.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class LocalStorage {
  Future<void> write(String key, Map<String, dynamic> json);
  Future<Map<String, dynamic>?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
  Future<bool> containsKey(String key);
}

class SharedPreferencesStorage implements LocalStorage {
  final SharedPreferences _prefs;

  SharedPreferencesStorage(this._prefs);

  @override
  Future<void> write(String key, Map<String, dynamic> json) async {
    final jsonString = jsonEncode(json);
    await _prefs.setString(key, jsonString);
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Invalid JSON, return null
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _prefs.containsKey(key);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('LocalStorage must be initialized in main()');
});
