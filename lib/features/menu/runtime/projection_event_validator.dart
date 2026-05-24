// lib/features/menu/runtime/projection_event_validator.dart
import 'package:talker_flutter/talker_flutter.dart';
import 'replay_cursor_manager.dart';
import 'snapshot_registry.dart';

enum EventValidationResult {
  valid,
  staleSequence,
  staleEpoch,
  sequenceGap,
  invalidChecksum,
}

class ProjectionEvent {
  final int eventSequence;
  final int projectionRevision;
  final int runtimeEpoch;
  final String projectionId;
  final String? checksum;
  final dynamic payload;

  const ProjectionEvent({
    required this.eventSequence,
    required this.projectionRevision,
    required this.runtimeEpoch,
    required this.projectionId,
    this.checksum,
    required this.payload,
  });
}

class ProjectionEventValidator {
  final Talker _talker;

  ProjectionEventValidator(this._talker);

  /// Validates an incoming transport event against the current ReplayCursor and Epoch.
  EventValidationResult validateEvent({
    required ProjectionEvent event,
    required ReplayCursor cursor,
    required ProjectionEpoch currentEpoch,
  }) {
    // 1. Runtime Epoch Validation
    if (event.runtimeEpoch < currentEpoch.runtimeEpoch) {
      _talker.warning(
        '[EventValidator] Stale event rejected. '
        'Event epoch: ${event.runtimeEpoch}, Current epoch: ${currentEpoch.runtimeEpoch}'
      );
      return EventValidationResult.staleEpoch;
    }

    // 2. Monotonic Sequence Validation
    if (event.eventSequence <= cursor.lastEventSequence) {
      _talker.debug(
        '[EventValidator] Duplicate/Stale event ignored. '
        'Event sequence: ${event.eventSequence}, Cursor sequence: ${cursor.lastEventSequence}'
      );
      return EventValidationResult.staleSequence;
    }

    // 3. Sequence Gap Detection
    if (event.eventSequence > cursor.lastEventSequence + 1) {
      _talker.error(
        '[EventValidator] Sequence GAP detected! '
        'Expected: ${cursor.lastEventSequence + 1}, Got: ${event.eventSequence}'
      );
      return EventValidationResult.sequenceGap;
    }

    // 4. (Optional) Checksum pre-validation if the event carries an expected checksum
    // Note: Deep payload checksum validation usually happens after reduction, 
    // but lightweight envelope checks can happen here.
    
    return EventValidationResult.valid;
  }
}
