// lib/features/menu/runtime/snapshot_migration.dart
import 'package:talker_flutter/talker_flutter.dart';
import '../domain/repositories/menu_repository.dart';

class SnapshotMigration {
  static const String currentSchemaVersion = 'v2.0.0';

  final MenuRepository _repository;
  final Talker _talker;

  const SnapshotMigration({
    required MenuRepository repository,
    required Talker talker,
  }) : _repository = repository,
       _talker = talker;

  /// Check if the cached snapshot version is compatible.
  /// If incompatible or null, triggers cache invalidation for the branch.
  Future<bool> verifyAndMigrate(String branchId) async {
    try {
      final cached = await _repository.getCachedMenuSnapshot(branchId);
      if (cached == null) {
        _talker.info('[Migration] No local cache found for branch: $branchId');
        return true;
      }

      final cachedVersion = cached.snapshotVersion;
      _talker.info(
        '[Migration] Cached version: $cachedVersion, Current code version: $currentSchemaVersion',
      );

      if (cachedVersion != currentSchemaVersion) {
        _talker.warning('[Migration] Version mismatch! Invalidation required.');
        await _repository.clearCache(branchId);
        _talker.info(
          '[Migration] Cache successfully cleared/invalidated for $branchId',
        );
        return false;
      }

      return true;
    } catch (e) {
      _talker.error(
        '[Migration] Failed during verification: $e. Clearing cache to be safe.',
      );
      await _repository.clearCache(branchId);
      return false;
    }
  }
}
