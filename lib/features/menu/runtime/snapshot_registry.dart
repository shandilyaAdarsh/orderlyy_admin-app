// lib/features/menu/runtime/snapshot_registry.dart
import 'package:talker_flutter/talker_flutter.dart';
import '../domain/entities/menu_snapshot.dart';

/// Classifies the reason a projection rebuild was triggered.
enum RebuildSource {
  integrityFailure,
  sequenceGap,
  snapshotVersionMismatch,
  tombstoneConflict,
  manualInvalidation,
  runtimeReset,
}

/// Defines the projection epoch context.
class ProjectionEpoch {
  final int projectionEpoch;
  final int runtimeEpoch;
  final int rebuildEpoch;
  final DateTime generatedAt;

  const ProjectionEpoch({
    required this.projectionEpoch,
    required this.runtimeEpoch,
    required this.rebuildEpoch,
    required this.generatedAt,
  });

  /// Increments the rebuild epoch when a rebuild occurs.
  ProjectionEpoch incrementRebuild() {
    return ProjectionEpoch(
      projectionEpoch: projectionEpoch,
      runtimeEpoch: runtimeEpoch,
      rebuildEpoch: rebuildEpoch + 1,
      generatedAt: DateTime.now(),
    );
  }
}

/// Authoritative snapshot identity, lineage, and replay baseline coordination.
class SnapshotRegistry {
  final Talker _talker;
  
  MenuSnapshot? _activeSnapshot;
  ProjectionEpoch _currentEpoch;

  SnapshotRegistry(this._talker)
      : _currentEpoch = ProjectionEpoch(
          projectionEpoch: 1,
          runtimeEpoch: 1,
          rebuildEpoch: 1,
          generatedAt: DateTime.now(),
        );

  MenuSnapshot? get activeSnapshot => _activeSnapshot;
  ProjectionEpoch get currentEpoch => _currentEpoch;

  /// Registers a newly fetched or generated snapshot as the authoritative baseline.
  void registerBaseline(MenuSnapshot snapshot, {RebuildSource? source}) {
    _activeSnapshot = snapshot;
    
    if (source != null) {
      _talker.info('[SnapshotRegistry] Rebuild triggered by ${source.name}. Incrementing rebuild epoch.');
      _currentEpoch = _currentEpoch.incrementRebuild();
    }

    _talker.info(
      '[SnapshotRegistry] Registered baseline snapshot: ${snapshot.snapshotVersion} '
      '(Epoch: ${_currentEpoch.projectionEpoch}.${_currentEpoch.runtimeEpoch}.${_currentEpoch.rebuildEpoch})'
    );
  }

  /// Verifies if a given replay event is valid against the current epoch.
  bool isValidReplayTarget(int eventRuntimeEpoch) {
    if (eventRuntimeEpoch < _currentEpoch.runtimeEpoch) {
      _talker.warning(
        '[SnapshotRegistry] Rejected stale replay event. '
        'Event epoch: $eventRuntimeEpoch, Current: ${_currentEpoch.runtimeEpoch}'
      );
      return false;
    }
    return true;
  }

  /// Clears the active snapshot, typically on tenant switch or hard reset.
  void resetRegistry() {
    _talker.warning('[SnapshotRegistry] Hard reset triggered.');
    _activeSnapshot = null;
    _currentEpoch = ProjectionEpoch(
      projectionEpoch: _currentEpoch.projectionEpoch + 1,
      runtimeEpoch: _currentEpoch.runtimeEpoch + 1,
      rebuildEpoch: 1,
      generatedAt: DateTime.now(),
    );
  }
}
