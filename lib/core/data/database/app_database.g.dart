// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReplayCursorsTable extends ReplayCursors
    with TableInfo<$ReplayCursorsTable, ReplayCursorEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReplayCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _projectionIdMeta = const VerificationMeta(
    'projectionId',
  );
  @override
  late final GeneratedColumn<String> projectionId = GeneratedColumn<String>(
    'projection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastEventSequenceMeta = const VerificationMeta(
    'lastEventSequence',
  );
  @override
  late final GeneratedColumn<int> lastEventSequence = GeneratedColumn<int>(
    'last_event_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastProjectionRevisionMeta =
      const VerificationMeta('lastProjectionRevision');
  @override
  late final GeneratedColumn<int> lastProjectionRevision = GeneratedColumn<int>(
    'last_projection_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectionChecksumMeta =
      const VerificationMeta('projectionChecksum');
  @override
  late final GeneratedColumn<String> projectionChecksum =
      GeneratedColumn<String>(
        'projection_checksum',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _runtimeEpochMeta = const VerificationMeta(
    'runtimeEpoch',
  );
  @override
  late final GeneratedColumn<int> runtimeEpoch = GeneratedColumn<int>(
    'runtime_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSnapshotIdMeta = const VerificationMeta(
    'lastSnapshotId',
  );
  @override
  late final GeneratedColumn<String> lastSnapshotId = GeneratedColumn<String>(
    'last_snapshot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    projectionId,
    lastEventSequence,
    lastProjectionRevision,
    projectionChecksum,
    runtimeEpoch,
    lastSnapshotId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'replay_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplayCursorEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('projection_id')) {
      context.handle(
        _projectionIdMeta,
        projectionId.isAcceptableOrUnknown(
          data['projection_id']!,
          _projectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectionIdMeta);
    }
    if (data.containsKey('last_event_sequence')) {
      context.handle(
        _lastEventSequenceMeta,
        lastEventSequence.isAcceptableOrUnknown(
          data['last_event_sequence']!,
          _lastEventSequenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastEventSequenceMeta);
    }
    if (data.containsKey('last_projection_revision')) {
      context.handle(
        _lastProjectionRevisionMeta,
        lastProjectionRevision.isAcceptableOrUnknown(
          data['last_projection_revision']!,
          _lastProjectionRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastProjectionRevisionMeta);
    }
    if (data.containsKey('projection_checksum')) {
      context.handle(
        _projectionChecksumMeta,
        projectionChecksum.isAcceptableOrUnknown(
          data['projection_checksum']!,
          _projectionChecksumMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectionChecksumMeta);
    }
    if (data.containsKey('runtime_epoch')) {
      context.handle(
        _runtimeEpochMeta,
        runtimeEpoch.isAcceptableOrUnknown(
          data['runtime_epoch']!,
          _runtimeEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_runtimeEpochMeta);
    }
    if (data.containsKey('last_snapshot_id')) {
      context.handle(
        _lastSnapshotIdMeta,
        lastSnapshotId.isAcceptableOrUnknown(
          data['last_snapshot_id']!,
          _lastSnapshotIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {projectionId};
  @override
  ReplayCursorEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplayCursorEntry(
      projectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}projection_id'],
      )!,
      lastEventSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_event_sequence'],
      )!,
      lastProjectionRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_projection_revision'],
      )!,
      projectionChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}projection_checksum'],
      )!,
      runtimeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime_epoch'],
      )!,
      lastSnapshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_snapshot_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReplayCursorsTable createAlias(String alias) {
    return $ReplayCursorsTable(attachedDatabase, alias);
  }
}

class ReplayCursorEntry extends DataClass
    implements Insertable<ReplayCursorEntry> {
  final String projectionId;
  final int lastEventSequence;
  final int lastProjectionRevision;
  final String projectionChecksum;
  final int runtimeEpoch;
  final String? lastSnapshotId;
  final DateTime updatedAt;
  const ReplayCursorEntry({
    required this.projectionId,
    required this.lastEventSequence,
    required this.lastProjectionRevision,
    required this.projectionChecksum,
    required this.runtimeEpoch,
    this.lastSnapshotId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['projection_id'] = Variable<String>(projectionId);
    map['last_event_sequence'] = Variable<int>(lastEventSequence);
    map['last_projection_revision'] = Variable<int>(lastProjectionRevision);
    map['projection_checksum'] = Variable<String>(projectionChecksum);
    map['runtime_epoch'] = Variable<int>(runtimeEpoch);
    if (!nullToAbsent || lastSnapshotId != null) {
      map['last_snapshot_id'] = Variable<String>(lastSnapshotId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReplayCursorsCompanion toCompanion(bool nullToAbsent) {
    return ReplayCursorsCompanion(
      projectionId: Value(projectionId),
      lastEventSequence: Value(lastEventSequence),
      lastProjectionRevision: Value(lastProjectionRevision),
      projectionChecksum: Value(projectionChecksum),
      runtimeEpoch: Value(runtimeEpoch),
      lastSnapshotId: lastSnapshotId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSnapshotId),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReplayCursorEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplayCursorEntry(
      projectionId: serializer.fromJson<String>(json['projectionId']),
      lastEventSequence: serializer.fromJson<int>(json['lastEventSequence']),
      lastProjectionRevision: serializer.fromJson<int>(
        json['lastProjectionRevision'],
      ),
      projectionChecksum: serializer.fromJson<String>(
        json['projectionChecksum'],
      ),
      runtimeEpoch: serializer.fromJson<int>(json['runtimeEpoch']),
      lastSnapshotId: serializer.fromJson<String?>(json['lastSnapshotId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'projectionId': serializer.toJson<String>(projectionId),
      'lastEventSequence': serializer.toJson<int>(lastEventSequence),
      'lastProjectionRevision': serializer.toJson<int>(lastProjectionRevision),
      'projectionChecksum': serializer.toJson<String>(projectionChecksum),
      'runtimeEpoch': serializer.toJson<int>(runtimeEpoch),
      'lastSnapshotId': serializer.toJson<String?>(lastSnapshotId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReplayCursorEntry copyWith({
    String? projectionId,
    int? lastEventSequence,
    int? lastProjectionRevision,
    String? projectionChecksum,
    int? runtimeEpoch,
    Value<String?> lastSnapshotId = const Value.absent(),
    DateTime? updatedAt,
  }) => ReplayCursorEntry(
    projectionId: projectionId ?? this.projectionId,
    lastEventSequence: lastEventSequence ?? this.lastEventSequence,
    lastProjectionRevision:
        lastProjectionRevision ?? this.lastProjectionRevision,
    projectionChecksum: projectionChecksum ?? this.projectionChecksum,
    runtimeEpoch: runtimeEpoch ?? this.runtimeEpoch,
    lastSnapshotId: lastSnapshotId.present
        ? lastSnapshotId.value
        : this.lastSnapshotId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReplayCursorEntry copyWithCompanion(ReplayCursorsCompanion data) {
    return ReplayCursorEntry(
      projectionId: data.projectionId.present
          ? data.projectionId.value
          : this.projectionId,
      lastEventSequence: data.lastEventSequence.present
          ? data.lastEventSequence.value
          : this.lastEventSequence,
      lastProjectionRevision: data.lastProjectionRevision.present
          ? data.lastProjectionRevision.value
          : this.lastProjectionRevision,
      projectionChecksum: data.projectionChecksum.present
          ? data.projectionChecksum.value
          : this.projectionChecksum,
      runtimeEpoch: data.runtimeEpoch.present
          ? data.runtimeEpoch.value
          : this.runtimeEpoch,
      lastSnapshotId: data.lastSnapshotId.present
          ? data.lastSnapshotId.value
          : this.lastSnapshotId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplayCursorEntry(')
          ..write('projectionId: $projectionId, ')
          ..write('lastEventSequence: $lastEventSequence, ')
          ..write('lastProjectionRevision: $lastProjectionRevision, ')
          ..write('projectionChecksum: $projectionChecksum, ')
          ..write('runtimeEpoch: $runtimeEpoch, ')
          ..write('lastSnapshotId: $lastSnapshotId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    projectionId,
    lastEventSequence,
    lastProjectionRevision,
    projectionChecksum,
    runtimeEpoch,
    lastSnapshotId,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplayCursorEntry &&
          other.projectionId == this.projectionId &&
          other.lastEventSequence == this.lastEventSequence &&
          other.lastProjectionRevision == this.lastProjectionRevision &&
          other.projectionChecksum == this.projectionChecksum &&
          other.runtimeEpoch == this.runtimeEpoch &&
          other.lastSnapshotId == this.lastSnapshotId &&
          other.updatedAt == this.updatedAt);
}

class ReplayCursorsCompanion extends UpdateCompanion<ReplayCursorEntry> {
  final Value<String> projectionId;
  final Value<int> lastEventSequence;
  final Value<int> lastProjectionRevision;
  final Value<String> projectionChecksum;
  final Value<int> runtimeEpoch;
  final Value<String?> lastSnapshotId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReplayCursorsCompanion({
    this.projectionId = const Value.absent(),
    this.lastEventSequence = const Value.absent(),
    this.lastProjectionRevision = const Value.absent(),
    this.projectionChecksum = const Value.absent(),
    this.runtimeEpoch = const Value.absent(),
    this.lastSnapshotId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReplayCursorsCompanion.insert({
    required String projectionId,
    required int lastEventSequence,
    required int lastProjectionRevision,
    required String projectionChecksum,
    required int runtimeEpoch,
    this.lastSnapshotId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : projectionId = Value(projectionId),
       lastEventSequence = Value(lastEventSequence),
       lastProjectionRevision = Value(lastProjectionRevision),
       projectionChecksum = Value(projectionChecksum),
       runtimeEpoch = Value(runtimeEpoch);
  static Insertable<ReplayCursorEntry> custom({
    Expression<String>? projectionId,
    Expression<int>? lastEventSequence,
    Expression<int>? lastProjectionRevision,
    Expression<String>? projectionChecksum,
    Expression<int>? runtimeEpoch,
    Expression<String>? lastSnapshotId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (projectionId != null) 'projection_id': projectionId,
      if (lastEventSequence != null) 'last_event_sequence': lastEventSequence,
      if (lastProjectionRevision != null)
        'last_projection_revision': lastProjectionRevision,
      if (projectionChecksum != null) 'projection_checksum': projectionChecksum,
      if (runtimeEpoch != null) 'runtime_epoch': runtimeEpoch,
      if (lastSnapshotId != null) 'last_snapshot_id': lastSnapshotId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReplayCursorsCompanion copyWith({
    Value<String>? projectionId,
    Value<int>? lastEventSequence,
    Value<int>? lastProjectionRevision,
    Value<String>? projectionChecksum,
    Value<int>? runtimeEpoch,
    Value<String?>? lastSnapshotId,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReplayCursorsCompanion(
      projectionId: projectionId ?? this.projectionId,
      lastEventSequence: lastEventSequence ?? this.lastEventSequence,
      lastProjectionRevision:
          lastProjectionRevision ?? this.lastProjectionRevision,
      projectionChecksum: projectionChecksum ?? this.projectionChecksum,
      runtimeEpoch: runtimeEpoch ?? this.runtimeEpoch,
      lastSnapshotId: lastSnapshotId ?? this.lastSnapshotId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (projectionId.present) {
      map['projection_id'] = Variable<String>(projectionId.value);
    }
    if (lastEventSequence.present) {
      map['last_event_sequence'] = Variable<int>(lastEventSequence.value);
    }
    if (lastProjectionRevision.present) {
      map['last_projection_revision'] = Variable<int>(
        lastProjectionRevision.value,
      );
    }
    if (projectionChecksum.present) {
      map['projection_checksum'] = Variable<String>(projectionChecksum.value);
    }
    if (runtimeEpoch.present) {
      map['runtime_epoch'] = Variable<int>(runtimeEpoch.value);
    }
    if (lastSnapshotId.present) {
      map['last_snapshot_id'] = Variable<String>(lastSnapshotId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReplayCursorsCompanion(')
          ..write('projectionId: $projectionId, ')
          ..write('lastEventSequence: $lastEventSequence, ')
          ..write('lastProjectionRevision: $lastProjectionRevision, ')
          ..write('projectionChecksum: $projectionChecksum, ')
          ..write('runtimeEpoch: $runtimeEpoch, ')
          ..write('lastSnapshotId: $lastSnapshotId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MutationJournalTable extends MutationJournal
    with TableInfo<$MutationJournalTable, MutationJournalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MutationJournalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mutationIdMeta = const VerificationMeta(
    'mutationId',
  );
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    mutationId,
    status,
    payload,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mutation_journal';
  @override
  VerificationContext validateIntegrity(
    Insertable<MutationJournalEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mutation_id')) {
      context.handle(
        _mutationIdMeta,
        mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mutationId};
  @override
  MutationJournalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MutationJournalEntry(
      mutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MutationJournalTable createAlias(String alias) {
    return $MutationJournalTable(attachedDatabase, alias);
  }
}

class MutationJournalEntry extends DataClass
    implements Insertable<MutationJournalEntry> {
  final String mutationId;
  final String status;
  final String payload;
  final DateTime createdAt;
  const MutationJournalEntry({
    required this.mutationId,
    required this.status,
    required this.payload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mutation_id'] = Variable<String>(mutationId);
    map['status'] = Variable<String>(status);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MutationJournalCompanion toCompanion(bool nullToAbsent) {
    return MutationJournalCompanion(
      mutationId: Value(mutationId),
      status: Value(status),
      payload: Value(payload),
      createdAt: Value(createdAt),
    );
  }

  factory MutationJournalEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MutationJournalEntry(
      mutationId: serializer.fromJson<String>(json['mutationId']),
      status: serializer.fromJson<String>(json['status']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mutationId': serializer.toJson<String>(mutationId),
      'status': serializer.toJson<String>(status),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MutationJournalEntry copyWith({
    String? mutationId,
    String? status,
    String? payload,
    DateTime? createdAt,
  }) => MutationJournalEntry(
    mutationId: mutationId ?? this.mutationId,
    status: status ?? this.status,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
  );
  MutationJournalEntry copyWithCompanion(MutationJournalCompanion data) {
    return MutationJournalEntry(
      mutationId: data.mutationId.present
          ? data.mutationId.value
          : this.mutationId,
      status: data.status.present ? data.status.value : this.status,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MutationJournalEntry(')
          ..write('mutationId: $mutationId, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mutationId, status, payload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MutationJournalEntry &&
          other.mutationId == this.mutationId &&
          other.status == this.status &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt);
}

class MutationJournalCompanion extends UpdateCompanion<MutationJournalEntry> {
  final Value<String> mutationId;
  final Value<String> status;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MutationJournalCompanion({
    this.mutationId = const Value.absent(),
    this.status = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MutationJournalCompanion.insert({
    required String mutationId,
    required String status,
    required String payload,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mutationId = Value(mutationId),
       status = Value(status),
       payload = Value(payload);
  static Insertable<MutationJournalEntry> custom({
    Expression<String>? mutationId,
    Expression<String>? status,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mutationId != null) 'mutation_id': mutationId,
      if (status != null) 'status': status,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MutationJournalCompanion copyWith({
    Value<String>? mutationId,
    Value<String>? status,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MutationJournalCompanion(
      mutationId: mutationId ?? this.mutationId,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MutationJournalCompanion(')
          ..write('mutationId: $mutationId, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReplayCursorsTable replayCursors = $ReplayCursorsTable(this);
  late final $MutationJournalTable mutationJournal = $MutationJournalTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    replayCursors,
    mutationJournal,
  ];
}

typedef $$ReplayCursorsTableCreateCompanionBuilder =
    ReplayCursorsCompanion Function({
      required String projectionId,
      required int lastEventSequence,
      required int lastProjectionRevision,
      required String projectionChecksum,
      required int runtimeEpoch,
      Value<String?> lastSnapshotId,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ReplayCursorsTableUpdateCompanionBuilder =
    ReplayCursorsCompanion Function({
      Value<String> projectionId,
      Value<int> lastEventSequence,
      Value<int> lastProjectionRevision,
      Value<String> projectionChecksum,
      Value<int> runtimeEpoch,
      Value<String?> lastSnapshotId,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ReplayCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $ReplayCursorsTable> {
  $$ReplayCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get projectionId => $composableBuilder(
    column: $table.projectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastEventSequence => $composableBuilder(
    column: $table.lastEventSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastProjectionRevision => $composableBuilder(
    column: $table.lastProjectionRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectionChecksum => $composableBuilder(
    column: $table.projectionChecksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtimeEpoch => $composableBuilder(
    column: $table.runtimeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSnapshotId => $composableBuilder(
    column: $table.lastSnapshotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReplayCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReplayCursorsTable> {
  $$ReplayCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get projectionId => $composableBuilder(
    column: $table.projectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastEventSequence => $composableBuilder(
    column: $table.lastEventSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastProjectionRevision => $composableBuilder(
    column: $table.lastProjectionRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectionChecksum => $composableBuilder(
    column: $table.projectionChecksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtimeEpoch => $composableBuilder(
    column: $table.runtimeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSnapshotId => $composableBuilder(
    column: $table.lastSnapshotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReplayCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReplayCursorsTable> {
  $$ReplayCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get projectionId => $composableBuilder(
    column: $table.projectionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastEventSequence => $composableBuilder(
    column: $table.lastEventSequence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastProjectionRevision => $composableBuilder(
    column: $table.lastProjectionRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectionChecksum => $composableBuilder(
    column: $table.projectionChecksum,
    builder: (column) => column,
  );

  GeneratedColumn<int> get runtimeEpoch => $composableBuilder(
    column: $table.runtimeEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSnapshotId => $composableBuilder(
    column: $table.lastSnapshotId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReplayCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReplayCursorsTable,
          ReplayCursorEntry,
          $$ReplayCursorsTableFilterComposer,
          $$ReplayCursorsTableOrderingComposer,
          $$ReplayCursorsTableAnnotationComposer,
          $$ReplayCursorsTableCreateCompanionBuilder,
          $$ReplayCursorsTableUpdateCompanionBuilder,
          (
            ReplayCursorEntry,
            BaseReferences<
              _$AppDatabase,
              $ReplayCursorsTable,
              ReplayCursorEntry
            >,
          ),
          ReplayCursorEntry,
          PrefetchHooks Function()
        > {
  $$ReplayCursorsTableTableManager(_$AppDatabase db, $ReplayCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReplayCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReplayCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReplayCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> projectionId = const Value.absent(),
                Value<int> lastEventSequence = const Value.absent(),
                Value<int> lastProjectionRevision = const Value.absent(),
                Value<String> projectionChecksum = const Value.absent(),
                Value<int> runtimeEpoch = const Value.absent(),
                Value<String?> lastSnapshotId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReplayCursorsCompanion(
                projectionId: projectionId,
                lastEventSequence: lastEventSequence,
                lastProjectionRevision: lastProjectionRevision,
                projectionChecksum: projectionChecksum,
                runtimeEpoch: runtimeEpoch,
                lastSnapshotId: lastSnapshotId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String projectionId,
                required int lastEventSequence,
                required int lastProjectionRevision,
                required String projectionChecksum,
                required int runtimeEpoch,
                Value<String?> lastSnapshotId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReplayCursorsCompanion.insert(
                projectionId: projectionId,
                lastEventSequence: lastEventSequence,
                lastProjectionRevision: lastProjectionRevision,
                projectionChecksum: projectionChecksum,
                runtimeEpoch: runtimeEpoch,
                lastSnapshotId: lastSnapshotId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReplayCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReplayCursorsTable,
      ReplayCursorEntry,
      $$ReplayCursorsTableFilterComposer,
      $$ReplayCursorsTableOrderingComposer,
      $$ReplayCursorsTableAnnotationComposer,
      $$ReplayCursorsTableCreateCompanionBuilder,
      $$ReplayCursorsTableUpdateCompanionBuilder,
      (
        ReplayCursorEntry,
        BaseReferences<_$AppDatabase, $ReplayCursorsTable, ReplayCursorEntry>,
      ),
      ReplayCursorEntry,
      PrefetchHooks Function()
    >;
typedef $$MutationJournalTableCreateCompanionBuilder =
    MutationJournalCompanion Function({
      required String mutationId,
      required String status,
      required String payload,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$MutationJournalTableUpdateCompanionBuilder =
    MutationJournalCompanion Function({
      Value<String> mutationId,
      Value<String> status,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MutationJournalTableFilterComposer
    extends Composer<_$AppDatabase, $MutationJournalTable> {
  $$MutationJournalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MutationJournalTableOrderingComposer
    extends Composer<_$AppDatabase, $MutationJournalTable> {
  $$MutationJournalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MutationJournalTableAnnotationComposer
    extends Composer<_$AppDatabase, $MutationJournalTable> {
  $$MutationJournalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MutationJournalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MutationJournalTable,
          MutationJournalEntry,
          $$MutationJournalTableFilterComposer,
          $$MutationJournalTableOrderingComposer,
          $$MutationJournalTableAnnotationComposer,
          $$MutationJournalTableCreateCompanionBuilder,
          $$MutationJournalTableUpdateCompanionBuilder,
          (
            MutationJournalEntry,
            BaseReferences<
              _$AppDatabase,
              $MutationJournalTable,
              MutationJournalEntry
            >,
          ),
          MutationJournalEntry,
          PrefetchHooks Function()
        > {
  $$MutationJournalTableTableManager(
    _$AppDatabase db,
    $MutationJournalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MutationJournalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MutationJournalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MutationJournalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mutationId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MutationJournalCompanion(
                mutationId: mutationId,
                status: status,
                payload: payload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mutationId,
                required String status,
                required String payload,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MutationJournalCompanion.insert(
                mutationId: mutationId,
                status: status,
                payload: payload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MutationJournalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MutationJournalTable,
      MutationJournalEntry,
      $$MutationJournalTableFilterComposer,
      $$MutationJournalTableOrderingComposer,
      $$MutationJournalTableAnnotationComposer,
      $$MutationJournalTableCreateCompanionBuilder,
      $$MutationJournalTableUpdateCompanionBuilder,
      (
        MutationJournalEntry,
        BaseReferences<
          _$AppDatabase,
          $MutationJournalTable,
          MutationJournalEntry
        >,
      ),
      MutationJournalEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReplayCursorsTableTableManager get replayCursors =>
      $$ReplayCursorsTableTableManager(_db, _db.replayCursors);
  $$MutationJournalTableTableManager get mutationJournal =>
      $$MutationJournalTableTableManager(_db, _db.mutationJournal);
}
