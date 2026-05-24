// lib/features/orders/runtime/mutation_journal_service.dart
import 'package:drift/drift.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../../core/data/database/app_database.dart';

enum MutationStatus { pending, committed, failed, replayed }

class MutationJournalService {
  final AppDatabase _db;
  final Talker _talker;

  MutationJournalService(this._db, this._talker);

  /// Appends a new optimistic mutation to the journal.
  Future<void> appendMutation({
    required String mutationId,
    required String payload,
  }) async {
    await _db.into(_db.mutationJournal).insert(
      MutationJournalCompanion.insert(
        mutationId: mutationId,
        status: MutationStatus.pending.name,
        payload: payload,
      ),
    );
    _talker.debug('[MutationJournal] Appended mutation: $mutationId');
  }

  /// Retrieves all pending mutations in deterministic insertion order.
  Future<List<MutationJournalEntry>> getPendingMutations() async {
    return (_db.select(_db.mutationJournal)
          ..where((t) => t.status.equals(MutationStatus.pending.name))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
        .get();
  }

  /// Transitions a mutation's state safely.
  Future<void> updateMutationStatus(String mutationId, MutationStatus status) async {
    await (_db.update(_db.mutationJournal)
          ..where((t) => t.mutationId.equals(mutationId)))
        .write(MutationJournalCompanion(status: Value(status.name)));
    
    _talker.info('[MutationJournal] Mutation $mutationId transitioned to ${status.name}');
  }

  /// Flushes the queue by replaying pending mutations (e.g. upon reconnect).
  Future<void> replayPendingMutations(Future<bool> Function(MutationJournalEntry) replayCallback) async {
    final pending = await getPendingMutations();
    
    if (pending.isEmpty) return;
    
    _talker.info('[MutationJournal] Replaying ${pending.length} pending mutations...');
    
    for (final mutation in pending) {
      final success = await replayCallback(mutation);
      if (success) {
        await updateMutationStatus(mutation.mutationId, MutationStatus.replayed);
      } else {
        await updateMutationStatus(mutation.mutationId, MutationStatus.failed);
      }
    }
  }
}
