import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage {
  static const String _kDefaultBoxName = 'app_snapshot_cache';

  /// Initializes Hive and opens the default box.
  /// Must be called during the application bootstrap sequence in main.dart.
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_kDefaultBoxName);
  }

  final Box _box;

  HiveStorage([String boxName = _kDefaultBoxName]) : _box = Hive.box(boxName);

  /// Write a value to local storage.
  Future<void> write(String key, dynamic value) async {
    await _box.put(key, value);
  }

  /// Read a value from local storage.
  dynamic read(String key) {
    return _box.get(key);
  }

  /// Delete a value from local storage.
  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  /// Clear all cached data inside the box.
  Future<void> clear() async {
    await _box.clear();
  }

  /// Checks if a key exists in local storage.
  bool containsKey(String key) {
    return _box.containsKey(key);
  }
}
