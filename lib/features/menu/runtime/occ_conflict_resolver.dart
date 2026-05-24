// lib/features/menu/runtime/occ_conflict_resolver.dart
import 'package:talker_flutter/talker_flutter.dart';
import '../domain/entities/menu_snapshot.dart';
import 'merge_policy_registry.dart';

enum OccConflictState {
  resolvedAuto,
  requiresManualReview,
}

class OccConflictResult<T> {
  final bool hasConflict;
  final OccConflictState? state;
  final T reconciledState;
  final ConflictEnvelope? envelope;

  const OccConflictResult({
    required this.hasConflict,
    required this.reconciledState,
    this.state,
    this.envelope,
  });
}

class OccConflictResolver {
  final Talker _talker;

  OccConflictResolver(this._talker);

  /// Resolves concurrency conflicts using a deterministic three-way merge.
  /// Enforces field-level policies via MergePolicyRegistry and respects tombstones.
  OccConflictResult<MenuSnapshot> resolveSnapshotConflict({
    required MenuSnapshot localOptimistic,
    required MenuSnapshot serverAuthoritative,
    required int expectedBaseRevision,
    required String deviceId,
    required String sessionId,
    MenuSnapshot? baseSnapshot,
  }) {
    final serverRevisionStr = serverAuthoritative.snapshotVersion ?? '0';
    final serverRevision = int.tryParse(serverRevisionStr) ?? 0;

    // Case 1: No conflict. Server is at the expected base version.
    if (serverRevision == expectedBaseRevision) {
      _talker.info('[OCC] Version match ($expectedBaseRevision). Applying local changes.');
      return OccConflictResult(
        hasConflict: false,
        reconciledState: localOptimistic.copyWith(
          snapshotVersion: serverRevisionStr,
        ),
      );
    }

    // Case 2: Conflict detected. Server has progressed to a newer version in the interim.
    _talker.warning('[OCC] Concurrency conflict! Base: $expectedBaseRevision, Server: $serverRevision.');
    
    if (baseSnapshot == null) {
      _talker.warning('[OCC] No base snapshot provided. Falling back to server state.');
      return OccConflictResult(
        hasConflict: true,
        state: OccConflictState.requiresManualReview,
        reconciledState: serverAuthoritative,
        envelope: ConflictEnvelope(
          baseRevision: expectedBaseRevision,
          localRevision: expectedBaseRevision + 1,
          remoteRevision: serverRevision,
          mergePolicy: MergePolicy.manualReviewRequired,
          conflictFields: const ['ALL'],
          sourceDeviceId: deviceId,
          sourceSessionId: sessionId,
        ),
      );
    }

    // Case 3: Deterministic Three-way merge
    try {
      final mergedItems = <MenuItem>[];
      bool requiresReview = false;
      final conflictFields = <String>[];

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
          // Item deleted locally (either physically or logically)
          // Ensure we respect Tombstone rules. If server changed it, we might have a conflict.
          // But Tombstone policy dictates tombstone wins unless explicit restore.
          if (MergePolicyRegistry.getPolicyForField('deletedAt') == MergePolicy.tombstoneWins) {
            continue; // Tombstone wins. Do not add.
          }
        }

        final localChanged = localItem != baseItem;
        final serverChanged = serverItem != baseItem;

        if (localChanged && serverChanged) {
          // Both changed. Check field-level overlap.
          final Map<String, dynamic> mergedProps = {};
          
          bool mergeField<T>(String field, T baseVal, T localVal, T serverVal) {
            if (localVal != baseVal && serverVal != baseVal && localVal != serverVal) {
              final policy = MergePolicyRegistry.getPolicyForField(field);
              if (policy == MergePolicy.manualReviewRequired) {
                requiresReview = true;
                conflictFields.add(field);
                return false; // Server wins by default in conflict until reviewed
              } else if (policy == MergePolicy.lastWriteWins) {
                // In this optimistic system, local is technically the "last" write conceptually, 
                // but server is authoritative. We defer to server for strict LWW unless timestamps exist.
                return false;
              }
            }
            // Auto-merge non-colliding fields
            return (localVal != baseVal) ? true : false;
          }

          final useLocalCategory = mergeField('categoryId', baseItem.categoryId, localItem!.categoryId, serverItem.categoryId);
          final useLocalName = mergeField('name', baseItem.name, localItem.name, serverItem.name);
          final useLocalDesc = mergeField('description', baseItem.description, localItem.description, serverItem.description);
          final useLocalPrice = mergeField('price', baseItem.price, localItem.price, serverItem.price);
          final useLocalAvail = mergeField('isAvailable', baseItem.isAvailable, localItem.isAvailable, serverItem.isAvailable);

          // Modifiers (List comparison)
          bool listEquals(List a, List b) {
            if (a.length != b.length) return false;
            for (int i = 0; i < a.length; i++) {
              if (a[i] != b[i]) return false;
            }
            return true;
          }
          final useLocalMods = mergeField('modifierGroupIds', 
            baseItem.modifierGroupIds.join(','), 
            localItem.modifierGroupIds.join(','), 
            serverItem.modifierGroupIds.join(','));

          mergedItems.add(MenuItem(
            id: serverItem.id,
            categoryId: useLocalCategory ? localItem.categoryId : serverItem.categoryId,
            name: useLocalName ? localItem.name : serverItem.name,
            description: useLocalDesc ? localItem.description : serverItem.description,
            price: useLocalPrice ? localItem.price : serverItem.price,
            isAvailable: useLocalAvail ? localItem.isAvailable : serverItem.isAvailable,
            modifierGroupIds: useLocalMods ? localItem.modifierGroupIds : serverItem.modifierGroupIds,
            deletedAt: serverItem.deletedAt ?? localItem.deletedAt,
          ));

        } else if (localChanged) {
          mergedItems.add(localItem!);
        } else {
          mergedItems.add(serverItem);
        }
      }

      // Add local-only items
      for (final localItem in localOptimistic.items) {
        if (!baseItemMap.containsKey(localItem.id)) {
          mergedItems.add(localItem);
        }
      }

      final mergedSnapshot = serverAuthoritative.copyWith(
        items: mergedItems,
        snapshotVersion: serverRevisionStr,
      );

      if (requiresReview) {
        return OccConflictResult(
          hasConflict: true,
          state: OccConflictState.requiresManualReview,
          reconciledState: mergedSnapshot,
          envelope: ConflictEnvelope(
            baseRevision: expectedBaseRevision,
            localRevision: expectedBaseRevision + 1,
            remoteRevision: serverRevision,
            mergePolicy: MergePolicy.manualReviewRequired,
            conflictFields: conflictFields,
            sourceDeviceId: deviceId,
            sourceSessionId: sessionId,
          ),
        );
      }

      _talker.info('[OCC] Auto-merge successful.');
      return OccConflictResult(
        hasConflict: true,
        state: OccConflictState.resolvedAuto,
        reconciledState: mergedSnapshot,
      );
    } catch (e) {
      _talker.error('[OCC] Merge failed: $e');
      return OccConflictResult(
        hasConflict: true,
        state: OccConflictState.requiresManualReview,
        reconciledState: serverAuthoritative,
        envelope: ConflictEnvelope(
          baseRevision: expectedBaseRevision,
          localRevision: expectedBaseRevision + 1,
          remoteRevision: serverRevision,
          mergePolicy: MergePolicy.manualReviewRequired,
          conflictFields: const ['MERGE_FAILURE'],
          sourceDeviceId: deviceId,
          sourceSessionId: sessionId,
        ),
      );
    }
  }
}
