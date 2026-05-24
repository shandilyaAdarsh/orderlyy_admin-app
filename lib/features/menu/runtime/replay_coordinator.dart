// lib/features/menu/runtime/replay_coordinator.dart
import 'dart:async';
import 'package:talker_flutter/talker_flutter.dart';
import 'projection_event_validator.dart';
import 'replay_cursor_manager.dart';
import 'snapshot_registry.dart';

/// Callback invoked when a valid event is cleared for projection reduction.
typedef OnEventValidated = Future<void> Function(ProjectionEvent event);

/// Callback invoked when a rebuild is mandated due to unrecoverable state.
typedef OnRebuildRequired = Future<void> Function(RebuildSource source);

/// The ReplayCoordinator acts as the definitive boundary between the raw Transport Layer
/// (WebSockets) and the pure Projection Runtime.
class ReplayCoordinator {
  final ReplayCursorManager _cursorManager;
  final ProjectionEventValidator _validator;
  final SnapshotRegistry _registry;
  final Talker _talker;

  final OnEventValidated onEventValidated;
  final OnRebuildRequired onRebuildRequired;

  ReplayCoordinator({
    required ReplayCursorManager cursorManager,
    required ProjectionEventValidator validator,
    required SnapshotRegistry registry,
    required Talker talker,
    required this.onEventValidated,
    required this.onRebuildRequired,
  })  : _cursorManager = cursorManager,
        _validator = validator,
        _registry = registry,
        _talker = talker;

  /// Processes a raw event from the transport layer.
  Future<void> handleTransportEvent(ProjectionEvent event) async {
    final projectionId = event.projectionId;
    final cursor = await _cursorManager.getCursor(projectionId);

    // If no cursor exists, we must rebuild from snapshot before we can accept events.
    if (cursor == null) {
      _talker.warning('[ReplayCoordinator] No cursor for $projectionId. Forcing rebuild.');
      await onRebuildRequired(RebuildSource.sequenceGap);
      return;
    }

    final validationResult = _validator.validateEvent(
      event: event,
      cursor: cursor,
      currentEpoch: _registry.currentEpoch,
    );

    switch (validationResult) {
      case EventValidationResult.valid:
        // Pass to projection runtime
        await onEventValidated(event);
        
        // Update cursor
        await _cursorManager.updateCursor(
          ReplayCursor(
            projectionId: projectionId,
            lastEventSequence: event.eventSequence,
            lastProjectionRevision: event.projectionRevision,
            projectionChecksum: event.checksum ?? cursor.projectionChecksum,
            runtimeEpoch: event.runtimeEpoch,
            lastSnapshotId: cursor.lastSnapshotId,
          ),
        );
        break;

      case EventValidationResult.staleSequence:
      case EventValidationResult.staleEpoch:
        // Safely ignore, do not break stream
        break;

      case EventValidationResult.sequenceGap:
        _talker.error('[ReplayCoordinator] Sequence gap unrecoverable. Triggering rebuild.');
        await onRebuildRequired(RebuildSource.sequenceGap);
        break;

      case EventValidationResult.invalidChecksum:
        _talker.error('[ReplayCoordinator] Event checksum invalid. Triggering rebuild.');
        await onRebuildRequired(RebuildSource.integrityFailure);
        break;
    }
  }

  /// Forces an authoritative rebuild and clears the cursor.
  Future<void> triggerManualRebuild() async {
    _talker.warning('[ReplayCoordinator] Manual rebuild triggered.');
    await onRebuildRequired(RebuildSource.manualInvalidation);
  }
}
