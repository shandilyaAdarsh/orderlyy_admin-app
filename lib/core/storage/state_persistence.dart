// ── State Persistence Service ────────────────────────────────────────────────
// Handles saving and restoring serializable state.
// Enables crash recovery and offline-first architecture.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_storage.dart';

class StatePersistence {
  final LocalStorage _storage;

  StatePersistence(this._storage);

  // ── Save State ────────────────────────────────────────────────────────────

  Future<void> saveState(String key, Map<String, dynamic> state) async {
    try {
      await _storage.write(key, state);
    } catch (e) {
      // Log error but don't throw - persistence failure shouldn't crash app
      debugPrint('Failed to save state for $key: $e');
    }
  }

  // ── Load State ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> loadState(String key) async {
    try {
      return await _storage.read(key);
    } catch (e) {
      debugPrint('Failed to load state for $key: $e');
      return null;
    }
  }

  // ── Clear State ───────────────────────────────────────────────────────────

  Future<void> clearState(String key) async {
    try {
      await _storage.delete(key);
    } catch (e) {
      debugPrint('Failed to clear state for $key: $e');
    }
  }

  // ── Clear All States ──────────────────────────────────────────────────────

  Future<void> clearAllStates() async {
    try {
      await _storage.clear();
    } catch (e) {
      debugPrint('Failed to clear all states: $e');
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final statePersistenceProvider = Provider<StatePersistence>((ref) {
  final storage = ref.watch(localStorageProvider);
  return StatePersistence(storage);
});
