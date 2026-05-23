// lib/features/menu/runtime/occ_conflict_resolver.dart
import 'package:talker_flutter/talker_flutter.dart';
import '../domain/entities/menu_snapshot.dart';

class OccConflictResult<T> {
  final bool hasConflict;
  final T reconciledState;
  final String? conflictMessage;

  const OccConflictResult({
    required this.hasConflict,
    required this.reconciledState,
    this.conflictMessage,
  });
}

class OccConflictResolver {
  final Talker _talker;

  OccConflictResolver(this._talker);

  /// Resolves concurrency conflicts between the local optimistic MenuSnapshot
  /// and the authoritative server MenuSnapshot using version tokens.
  /// Uses a three-way merge algorithm if [baseSnapshot] is supplied.
  OccConflictResult<MenuSnapshot> resolveSnapshotConflict({
    required MenuSnapshot localOptimistic,
    required MenuSnapshot serverAuthoritative,
    required String expectedBaseVersion,
    MenuSnapshot? baseSnapshot,
  }) {
    final serverVersion = serverAuthoritative.snapshotVersion;

    // Case 1: No conflict. Server is at the expected base version.
    if (serverVersion == expectedBaseVersion) {
      _talker.info('[OCC] Version match: Server is at expected base version ($expectedBaseVersion). Applying local changes.');
      return OccConflictResult(
        hasConflict: false,
        reconciledState: localOptimistic.copyWith(
          snapshotVersion: serverVersion,
        ),
      );
    }

    // Case 2: Conflict detected. Server has progressed to a newer version in the interim.
    _talker.warning('[OCC] Concurrency conflict detected! Expected base version: $expectedBaseVersion, actual server version: $serverVersion.');
    
    if (baseSnapshot == null) {
      _talker.warning('[OCC] No base snapshot provided for three-way merge. Falling back to server state to preserve safety.');
      return OccConflictResult(
        hasConflict: true,
        reconciledState: serverAuthoritative,
        conflictMessage: 'Conflict detected and base version is unavailable to perform automatic merge.',
      );
    }

    // Case 3: Three-way merge
    try {
      final mergedItems = <MenuItem>[];
      bool overlapConflict = false;

      final baseItemMap = {for (final item in baseSnapshot.items) item.id: item};
      final localItemMap = {for (final item in localOptimistic.items) item.id: item};

      for (final serverItem in serverAuthoritative.items) {
        final baseItem = baseItemMap[serverItem.id];
        final localItem = localItemMap[serverItem.id];

        if (baseItem == null) {
          // Item added on the server, local doesn't know about it
          mergedItems.add(serverItem);
          continue;
        }

        if (localItem == null) {
          // Item deleted locally, check if server changed it
          final serverChanged = serverItem != baseItem;
          if (serverChanged) {
            // Server changed it, local deleted it: overlap conflict
            overlapConflict = true;
          }
          // If server didn't change it, let local deletion stand (do not add it)
          continue;
        }

        final localChanged = localItem != baseItem;
        final serverChanged = serverItem != baseItem;

        if (localChanged && serverChanged) {
          // Overlap conflict: both modified the same item
          if (localItem == serverItem) {
            // They made the exact same change: resolve cleanly
            mergedItems.add(localItem);
          } else {
            _talker.warning('[OCC] Overlap collision on item ${serverItem.id}. Both edited item differently.');
            overlapConflict = true;
            mergedItems.add(serverItem); // Server version takes precedence in conflict
          }
        } else if (localChanged) {
          // Only local changed: keep local change
          mergedItems.add(localItem);
        } else {
          // Only server changed, or neither changed: keep server change
          mergedItems.add(serverItem);
        }
      }

      // Add items that were added locally but are not present on the server
      for (final localItem in localOptimistic.items) {
        if (!baseItemMap.containsKey(localItem.id)) {
          mergedItems.add(localItem);
        }
      }

      if (overlapConflict) {
        return OccConflictResult(
          hasConflict: true,
          reconciledState: serverAuthoritative,
          conflictMessage: 'Collision detected: Another admin updated the same item you were editing.',
        );
      }

      _talker.info('[OCC] Three-way merge successfully completed.');
      final mergedSnapshot = serverAuthoritative.copyWith(
        items: mergedItems,
        snapshotVersion: serverVersion,
      );

      return OccConflictResult(
        hasConflict: false,
        reconciledState: mergedSnapshot,
      );
    } catch (e) {
      _talker.error('[OCC] Three-way merge failed: $e');
      return OccConflictResult(
        hasConflict: true,
        reconciledState: serverAuthoritative,
        conflictMessage: 'Failed to auto-merge changes: $e',
      );
    }
  }
}
