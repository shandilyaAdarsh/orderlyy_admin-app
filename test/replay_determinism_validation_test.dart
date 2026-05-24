import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:orderlli_admin/features/menu/runtime/projection_event_validator.dart';
import 'package:orderlli_admin/features/menu/runtime/replay_coordinator.dart';
import 'package:orderlli_admin/features/menu/runtime/replay_cursor_manager.dart';
import 'package:orderlli_admin/features/menu/runtime/snapshot_registry.dart';

// Mock ReplayCursorManager since we just want to validate memory state determinism
class InMemoryCursorManager implements ReplayCursorManager {
  ReplayCursor? _cursor;

  @override
  Future<ReplayCursor?> getCursor(String projectionId) async => _cursor;

  @override
  Future<void> updateCursor(ReplayCursor cursor) async {
    _cursor = cursor;
  }

  @override
  Future<void> clearCursor(String projectionId) async {
    _cursor = null;
  }
}

void main() {
  final talker = Talker();

  group('Replay Determinism Validation', () {
    late InMemoryCursorManager cursorManager;
    late ProjectionEventValidator validator;
    late SnapshotRegistry registry;
    late ReplayCoordinator coordinator;

    late List<ProjectionEvent> processedEvents;
    late int rebuildTriggers;
    late List<String> errorLogs;

    setUp(() {
      cursorManager = InMemoryCursorManager();
      validator = ProjectionEventValidator(talker);
      registry = SnapshotRegistry(talker);
      processedEvents = [];
      rebuildTriggers = 0;
      errorLogs = [];

      coordinator = ReplayCoordinator(
        cursorManager: cursorManager,
        validator: validator,
        registry: registry,
        talker: talker,
        onEventValidated: (event) async {
          processedEvents.add(event);
        },
        onRebuildRequired: (source) async {
          rebuildTriggers++;
          errorLogs.add('Rebuild Required: $source');
        },
      );
    });

    String computeStateChecksum(List<ProjectionEvent> events) {
      final combinedPayloads = events.map((e) => e.payload.toString()).join('|');
      final bytes = utf8.encode(combinedPayloads);
      return sha256.convert(bytes).toString();
    }

    test('1. Sequential ordered replay (100x -> same checksum)', () async {
      final List<ProjectionEvent> stream = List.generate(50, (i) => ProjectionEvent(
        eventSequence: i + 1,
        projectionRevision: i + 1,
        runtimeEpoch: 1,
        projectionId: 'menu_proj_1',
        payload: 'mutate_item_${i}',
      ));

      final Set<String> checksums = {};

      for (int run = 0; run < 100; run++) {
        processedEvents.clear();
        await cursorManager.updateCursor(const ReplayCursor(
          projectionId: 'menu_proj_1',
          lastEventSequence: 0,
          lastProjectionRevision: 0,
          runtimeEpoch: 1,
          lastSnapshotId: 'snap_base',
          projectionChecksum: 'hash',
        ));

        for (final event in stream) {
          await coordinator.handleTransportEvent(event);
        }

        checksums.add(computeStateChecksum(processedEvents));
      }

      expect(checksums.length, 1);
      print('Sequential 100x Checksum: \${checksums.first}');
    });

    test('2. Out-of-order replay rejection (sequence gap triggers rebuild)', () async {
      await cursorManager.updateCursor(const ReplayCursor(
        projectionId: 'menu_proj_1',
        lastEventSequence: 10,
        lastProjectionRevision: 10,
        runtimeEpoch: 1,
        lastSnapshotId: 'snap_base',
        projectionChecksum: 'hash',
      ));

      final outOfOrderEvent = ProjectionEvent(
        eventSequence: 12, // Gap! Expected 11
        projectionRevision: 11,
        runtimeEpoch: 1,
        projectionId: 'menu_proj_1',
        payload: 'mutation',
      );

      await coordinator.handleTransportEvent(outOfOrderEvent);

      expect(rebuildTriggers, 1);
      expect(errorLogs.last, contains('sequenceGap'));
      print('Out-of-order rejection passed: \${errorLogs.last}');
    });

    test('3. Duplicate event replay rejection (stale sequence ignored safely)', () async {
      await cursorManager.updateCursor(const ReplayCursor(
        projectionId: 'menu_proj_1',
        lastEventSequence: 10,
        lastProjectionRevision: 10,
        runtimeEpoch: 1,
        lastSnapshotId: 'snap_base',
        projectionChecksum: 'hash',
      ));

      final duplicateEvent = ProjectionEvent(
        eventSequence: 10, // Stale! Expected 11
        projectionRevision: 10,
        runtimeEpoch: 1,
        projectionId: 'menu_proj_1',
        payload: 'mutation',
      );

      await coordinator.handleTransportEvent(duplicateEvent);

      expect(processedEvents.isEmpty, isTrue);
      expect(rebuildTriggers, 0);
      print('Duplicate event safely ignored.');
    });

    test('4. Replay after reconnect resumes safely', () async {
      // Connect 1
      await cursorManager.updateCursor(const ReplayCursor(
        projectionId: 'menu_proj_1',
        lastEventSequence: 0,
        lastProjectionRevision: 0,
        runtimeEpoch: 1,
        lastSnapshotId: 'snap_base',
        projectionChecksum: 'hash',
      ));

      await coordinator.handleTransportEvent(ProjectionEvent(
        eventSequence: 1, projectionRevision: 1, runtimeEpoch: 1, projectionId: 'menu_proj_1', payload: 'A'
      ));
      await coordinator.handleTransportEvent(ProjectionEvent(
        eventSequence: 2, projectionRevision: 2, runtimeEpoch: 1, projectionId: 'menu_proj_1', payload: 'B'
      ));

      // Reconnect (Cursor remembers sequence 2)
      // Server resends from sequence 1
      await coordinator.handleTransportEvent(ProjectionEvent(
        eventSequence: 1, projectionRevision: 1, runtimeEpoch: 1, projectionId: 'menu_proj_1', payload: 'A'
      ));
      await coordinator.handleTransportEvent(ProjectionEvent(
        eventSequence: 2, projectionRevision: 2, runtimeEpoch: 1, projectionId: 'menu_proj_1', payload: 'B'
      ));
      await coordinator.handleTransportEvent(ProjectionEvent(
        eventSequence: 3, projectionRevision: 3, runtimeEpoch: 1, projectionId: 'menu_proj_1', payload: 'C'
      ));

      // A and B should have been ignored on reconnect. Only C processed.
      // But processedEvents contains A, B from first connect. Total should be A, B, C.
      expect(processedEvents.length, 3);
      expect(processedEvents.last.payload, 'C');
      print('Reconnect resumed safely.');
    });

    test('5. Replay after rebuild forces new epoch / cursor reset', () async {
      await coordinator.handleTransportEvent(ProjectionEvent(
        eventSequence: 1, projectionRevision: 1, runtimeEpoch: 1, projectionId: 'menu_proj_1', payload: 'A'
      ));
      
      // Forces rebuild due to no cursor.
      expect(rebuildTriggers, 1);
      print('Missing cursor forced rebuild correctly.');
    });
    
    test('6. Replay after invalidation (stale epoch rejected)', () async {
      await cursorManager.updateCursor(const ReplayCursor(
        projectionId: 'menu_proj_1',
        lastEventSequence: 10,
        lastProjectionRevision: 10,
        runtimeEpoch: 2, // Registry epoch advanced
        lastSnapshotId: 'snap_base',
        projectionChecksum: 'hash',
      ));
      registry.resetRegistry(); // advances epoch to 2

      final staleEpochEvent = ProjectionEvent(
        eventSequence: 11,
        projectionRevision: 11,
        runtimeEpoch: 1, // Stale!
        projectionId: 'menu_proj_1',
        payload: 'mutation',
      );

      await coordinator.handleTransportEvent(staleEpochEvent);

      expect(processedEvents.isEmpty, isTrue);
      expect(rebuildTriggers, 0);
      print('Stale epoch event safely ignored.');
    });
  });
}
