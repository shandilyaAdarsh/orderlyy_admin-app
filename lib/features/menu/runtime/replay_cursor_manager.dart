// lib/features/menu/runtime/replay_cursor_manager.dart
import 'package:drift/drift.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../../core/data/database/app_database.dart';

/// Contract for the replay cursor based on architecture review.
class ReplayCursor {
  final String projectionId;
  final int lastEventSequence;
  final int lastProjectionRevision;
  final String projectionChecksum;
  final int runtimeEpoch;
  final String? lastSnapshotId;

  const ReplayCursor({
    required this.projectionId,
    required this.lastEventSequence,
    required this.lastProjectionRevision,
    required this.projectionChecksum,
    required this.runtimeEpoch,
    this.lastSnapshotId,
  });

  factory ReplayCursor.fromEntry(ReplayCursorEntry entry) {
    return ReplayCursor(
      projectionId: entry.projectionId,
      lastEventSequence: entry.lastEventSequence,
      lastProjectionRevision: entry.lastProjectionRevision,
      projectionChecksum: entry.projectionChecksum,
      runtimeEpoch: entry.runtimeEpoch,
      lastSnapshotId: entry.lastSnapshotId,
    );
  }
}

class ReplayCursorManager {
  final AppDatabase _db;
  final Talker _talker;

  ReplayCursorManager(this._db, this._talker);

  /// Retrieves the persisted cursor for a given projection.
  Future<ReplayCursor?> getCursor(String projectionId) async {
    final entry = await (_db.select(_db.replayCursors)
          ..where((t) => t.projectionId.equals(projectionId)))
        .getSingleOrNull();

    if (entry != null) {
      _talker.info('[ReplayCursor] Loaded cursor for $projectionId (Seq: ${entry.lastEventSequence}, Rev: ${entry.lastProjectionRevision})');
      return ReplayCursor.fromEntry(entry);
    }
    
    _talker.warning('[ReplayCursor] No cursor found for $projectionId. Rebuild required.');
    return null;
  }

  /// Updates the cursor deterministically after applying an event.
  Future<void> updateCursor(ReplayCursor cursor) async {
    await _db.into(_db.replayCursors).insertOnConflictUpdate(
      ReplayCursorsCompanion.insert(
        projectionId: cursor.projectionId,
        lastEventSequence: cursor.lastEventSequence,
        lastProjectionRevision: cursor.lastProjectionRevision,
        projectionChecksum: cursor.projectionChecksum,
        runtimeEpoch: cursor.runtimeEpoch,
        lastSnapshotId: Value(cursor.lastSnapshotId),
        updatedAt: Value(DateTime.now()),
      ),
    );
    _talker.debug('[ReplayCursor] Updated cursor for ${cursor.projectionId}');
  }

  /// Clears the cursor (e.g. during a hard reset or integrity failure).
  Future<void> clearCursor(String projectionId) async {
    await (_db.delete(_db.replayCursors)
          ..where((t) => t.projectionId.equals(projectionId)))
        .go();
    _talker.warning('[ReplayCursor] Cleared cursor for $projectionId');
  }
}
