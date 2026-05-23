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
          // Check for attribute collision
          final bool categoryCollision = (localItem.categoryId != baseItem.categoryId &&
              serverItem.categoryId != baseItem.categoryId &&
              localItem.categoryId != serverItem.categoryId);
          final bool nameCollision = (localItem.name != baseItem.name &&
              serverItem.name != baseItem.name &&
              localItem.name != serverItem.name);
          final bool descriptionCollision = (localItem.description != baseItem.description &&
              serverItem.description != baseItem.description &&
              localItem.description != serverItem.description);
          final bool priceCollision = (localItem.price != baseItem.price &&
              serverItem.price != baseItem.price &&
              localItem.price != serverItem.price);
          final bool isAvailableCollision = (localItem.isAvailable != baseItem.isAvailable &&
              serverItem.isAvailable != baseItem.isAvailable &&
              localItem.isAvailable != serverItem.isAvailable);

          bool listEquals(List a, List b) {
            if (a.length != b.length) return false;
            for (int i = 0; i < a.length; i++) {
              if (a[i] != b[i]) return false;
            }
            return true;
          }

          final bool localModifiersChanged =
              !listEquals(localItem.modifierGroupIds, baseItem.modifierGroupIds);
          final bool serverModifiersChanged =
              !listEquals(serverItem.modifierGroupIds, baseItem.modifierGroupIds);
          final bool modifiersCollision = localModifiersChanged &&
              serverModifiersChanged &&
              !listEquals(localItem.modifierGroupIds, serverItem.modifierGroupIds);

          if (categoryCollision ||
              nameCollision ||
              descriptionCollision ||
              priceCollision ||
              isAvailableCollision ||
              modifiersCollision) {
            _talker.warning(
              '[OCC] Overlap collision on item ${serverItem.id}. Both edited same property differently.',
            );
            overlapConflict = true;
            mergedItems.add(serverItem); // Server version takes precedence in conflict
          } else {
            // Auto-merge non-colliding fields!
            final mergedItem = MenuItem(
              id: serverItem.id,
              categoryId: localItem.categoryId != baseItem.categoryId
                  ? localItem.categoryId
                  : serverItem.categoryId,
              name: localItem.name != baseItem.name ? localItem.name : serverItem.name,
              description: localItem.description != baseItem.description
                  ? localItem.description
                  : serverItem.description,
              price: localItem.price != baseItem.price ? localItem.price : serverItem.price,
              isAvailable: localItem.isAvailable != baseItem.isAvailable
                  ? localItem.isAvailable
                  : serverItem.isAvailable,
              modifierGroupIds:
                  localModifiersChanged ? localItem.modifierGroupIds : serverItem.modifierGroupIds,
            );
            mergedItems.add(mergedItem);
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
