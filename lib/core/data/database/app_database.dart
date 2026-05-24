// lib/core/data/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('ReplayCursorEntry')
class ReplayCursors extends Table {
  TextColumn get projectionId => text()(); // e.g. 'menu_branch_abc'
  IntColumn get lastEventSequence => integer()();
  IntColumn get lastProjectionRevision => integer()();
  TextColumn get projectionChecksum => text()();
  IntColumn get runtimeEpoch => integer()();
  TextColumn get lastSnapshotId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {projectionId};
}

@DataClassName('MutationJournalEntry')
class MutationJournal extends Table {
  TextColumn get mutationId => text()();
  TextColumn get status => text()(); // PENDING, COMMITTED, FAILED, REPLAYED
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {mutationId};
}

@DriftDatabase(tables: [ReplayCursors, MutationJournal])
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? e}) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'orderlli_runtime');
}
