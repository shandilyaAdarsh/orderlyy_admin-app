// lib/features/realtime/domain/entities/sync_operation.dart

enum SyncOperationType {
  acknowledgeCall,
  resolveCall,
  escalateCall,
  createCall,
  updateTableStatus,
  saveOrder,
}

enum SyncOperationStatus {
  queued,
  inflight,
  success,
  failed,
  conflict,
  retrying,
  discarded,
}

class SyncOperation {
  final String operationId;
  final SyncOperationType type;
  final SyncOperationStatus status;
  final String entityId;
  final String entityLabel; // e.g. 'Table 7', 'Order #1042'
  final DateTime queuedAt;
  final int retryCount;
  final int maxRetries;
  final DateTime? nextRetryAt;
  final String? errorMessage;

  const SyncOperation({
    required this.operationId,
    required this.type,
    required this.status,
    required this.entityId,
    required this.entityLabel,
    required this.queuedAt,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.nextRetryAt,
    this.errorMessage,
  });

  SyncOperation copyWith({
    String? operationId,
    SyncOperationType? type,
    SyncOperationStatus? status,
    String? entityId,
    String? entityLabel,
    DateTime? queuedAt,
    int? retryCount,
    int? maxRetries,
    DateTime? nextRetryAt,
    String? errorMessage,
    bool clearNextRetryAt = false,
    bool clearErrorMessage = false,
  }) {
    return SyncOperation(
      operationId: operationId ?? this.operationId,
      type: type ?? this.type,
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      entityLabel: entityLabel ?? this.entityLabel,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      nextRetryAt: clearNextRetryAt ? null : nextRetryAt ?? this.nextRetryAt,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  bool get isFailed => status == SyncOperationStatus.failed;
  bool get isConflict => status == SyncOperationStatus.conflict;
  bool get isQueued => status == SyncOperationStatus.queued;
  bool get isRetrying => status == SyncOperationStatus.retrying;
  bool get isInflight => status == SyncOperationStatus.inflight;
  bool get isSuccess => status == SyncOperationStatus.success;
  bool get isDiscarded => status == SyncOperationStatus.discarded;
  bool get canRetry => retryCount < maxRetries;

  Duration get age => DateTime.now().difference(queuedAt);

  String get typeLabel {
    switch (type) {
      case SyncOperationType.acknowledgeCall:
        return 'Acknowledge Call';
      case SyncOperationType.resolveCall:
        return 'Resolve Call';
      case SyncOperationType.escalateCall:
        return 'Escalate Call';
      case SyncOperationType.createCall:
        return 'Create Call';
      case SyncOperationType.updateTableStatus:
        return 'Update Table Status';
      case SyncOperationType.saveOrder:
        return 'Save Order';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncOperation &&
        other.operationId == operationId &&
        other.type == type &&
        other.status == status &&
        other.entityId == entityId &&
        other.entityLabel == entityLabel &&
        other.queuedAt == queuedAt &&
        other.retryCount == retryCount &&
        other.maxRetries == maxRetries &&
        other.nextRetryAt == nextRetryAt &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        operationId,
        type,
        status,
        entityId,
        entityLabel,
        queuedAt,
        retryCount,
        maxRetries,
        nextRetryAt,
        errorMessage,
      );

  @override
  String toString() =>
      'SyncOperation(id: $operationId, type: $type, status: $status, '
      'entity: $entityLabel, retries: $retryCount/$maxRetries)';
}
