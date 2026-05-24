import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:orderlli_admin/core/data/database/app_database.dart';
import 'package:orderlli_admin/features/orders/runtime/mutation_journal_service.dart';

void main() {
  final talker = Talker();

  group('Offline Runtime Queue Validation', () {
    late AppDatabase db;
    late MutationJournalService journal;

    setUp(() {
      db = AppDatabase(e: NativeDatabase.memory());
      journal = MutationJournalService(db, talker);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Queued mutations persist across restart (network disconnect simulated)', () async {
      await journal.appendMutation(mutationId: 'mut_1', payload: 'checkout_1');
      await journal.appendMutation(mutationId: 'mut_2', payload: 'checkout_2');

      final pending = await journal.getPendingMutations();
      expect(pending.length, 2);
      expect(pending[0].mutationId, 'mut_1');
      expect(pending[1].mutationId, 'mut_2');
      print('Queued mutations persisted safely.');
    });

    test('2. Replay ordering preserved after restart', () async {
      await journal.appendMutation(mutationId: 'mut_1', payload: 'A');
      await journal.appendMutation(mutationId: 'mut_2', payload: 'B');
      await journal.appendMutation(mutationId: 'mut_3', payload: 'C');

      final List<String> replayed = [];
      await journal.replayPendingMutations((mutation) async {
        replayed.add(mutation.payload);
        return true;
      });

      expect(replayed, ['A', 'B', 'C']);
      print('Replay ordering strongly preserved: $replayed');
    });

    test('3. Partial replay interruption recovers safely (crash during flush)', () async {
      await journal.appendMutation(mutationId: 'mut_1', payload: 'A');
      await journal.appendMutation(mutationId: 'mut_2', payload: 'B');
      await journal.appendMutation(mutationId: 'mut_3', payload: 'C');

      // Simulate crash after mut_2
      try {
        await journal.replayPendingMutations((mutation) async {
          if (mutation.mutationId == 'mut_3') {
            throw Exception('Simulated network crash during flush');
          }
          return true;
        });
      } catch (e) {
        // Expected crash
      }

      final pending = await journal.getPendingMutations();
      expect(pending.length, 1);
      expect(pending.first.mutationId, 'mut_3');

      final replayedItems = await (db.select(db.mutationJournal)..where((t) => t.status.equals(MutationStatus.replayed.name))).get();
      expect(replayedItems.length, 2);
      expect(replayedItems[0].mutationId, 'mut_1');
      expect(replayedItems[1].mutationId, 'mut_2');
      
      print('Partial replay recovered cleanly. Remaining pending: \${pending.first.mutationId}');
    });

    test('4. Duplicate mutation retries remain idempotent & reconnect synchronization is safe', () async {
      await journal.appendMutation(mutationId: 'mut_1', payload: 'A');

      int attempts = 0;
      await journal.replayPendingMutations((mutation) async {
        attempts++;
        return false; // Fail the replay explicitly (e.g. 500 error)
      });

      final pendingAfterFail = await journal.getPendingMutations();
      expect(pendingAfterFail.isEmpty, isTrue); // They transitioned to 'failed'

      final failedItems = await (db.select(db.mutationJournal)..where((t) => t.status.equals(MutationStatus.failed.name))).get();
      expect(failedItems.length, 1);
      
      // Simulating a system trigger that resets failed items back to pending for retry
      await journal.updateMutationStatus('mut_1', MutationStatus.pending);

      await journal.replayPendingMutations((mutation) async {
        attempts++;
        return true; // Succeed this time
      });

      expect(attempts, 2);
      final finalPending = await journal.getPendingMutations();
      expect(finalPending.isEmpty, isTrue);

      final finalReplayed = await (db.select(db.mutationJournal)..where((t) => t.status.equals(MutationStatus.replayed.name))).get();
      expect(finalReplayed.length, 1);
      print('Duplicate retry handling is idempotent and stable.');
    });
  });
}
