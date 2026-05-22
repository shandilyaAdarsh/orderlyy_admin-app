// lib/features/shift/domain/entities/shift_session.dart

import '../../../../core/network/sync_state.dart';

/// Lifecycle states of a single staff work-shift.
enum ShiftStatus { idle, starting, active, paused, closing, closed, error }

/// Immutable value object representing one staff member's active shift session.
class ShiftSession {
  final String shiftId;
  final String staffId;
  final String staffName;
  final String branchId;
  final ShiftStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int assignedTableCount;
  final int completedOrderCount;
  final int activeOrderCount;
  final int pendingCallCount;

  /// Service Level Agreement compliance rate in the range 0.0–1.0.
  final double slaComplianceRate;

  final SyncState syncState;

  const ShiftSession({
    required this.shiftId,
    required this.staffId,
    required this.staffName,
    required this.branchId,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.assignedTableCount,
    required this.completedOrderCount,
    required this.activeOrderCount,
    required this.pendingCallCount,
    required this.slaComplianceRate,
    this.syncState = SyncState.unknown,
  });

  /// Wall-clock elapsed time for this shift.
  /// Uses [endedAt] when the shift is finished, otherwise uses [DateTime.now].
  Duration get elapsed => endedAt != null
      ? endedAt!.difference(startedAt)
      : DateTime.now().difference(startedAt);

  ShiftSession copyWith({
    String? shiftId,
    String? staffId,
    String? staffName,
    String? branchId,
    ShiftStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    int? assignedTableCount,
    int? completedOrderCount,
    int? activeOrderCount,
    int? pendingCallCount,
    double? slaComplianceRate,
    SyncState? syncState,
  }) {
    return ShiftSession(
      shiftId: shiftId ?? this.shiftId,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      branchId: branchId ?? this.branchId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      assignedTableCount: assignedTableCount ?? this.assignedTableCount,
      completedOrderCount: completedOrderCount ?? this.completedOrderCount,
      activeOrderCount: activeOrderCount ?? this.activeOrderCount,
      pendingCallCount: pendingCallCount ?? this.pendingCallCount,
      slaComplianceRate: slaComplianceRate ?? this.slaComplianceRate,
      syncState: syncState ?? this.syncState,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftSession &&
          runtimeType == other.runtimeType &&
          shiftId == other.shiftId &&
          staffId == other.staffId &&
          status == other.status &&
          startedAt == other.startedAt &&
          endedAt == other.endedAt &&
          assignedTableCount == other.assignedTableCount &&
          completedOrderCount == other.completedOrderCount &&
          activeOrderCount == other.activeOrderCount &&
          pendingCallCount == other.pendingCallCount &&
          slaComplianceRate == other.slaComplianceRate &&
          syncState == other.syncState;

  @override
  int get hashCode => Object.hash(
        shiftId,
        staffId,
        status,
        startedAt,
        endedAt,
        assignedTableCount,
        completedOrderCount,
        activeOrderCount,
        pendingCallCount,
        slaComplianceRate,
        syncState,
      );

  @override
  String toString() => 'ShiftSession('
      'shiftId: $shiftId, '
      'staffId: $staffId, '
      'status: $status, '
      'elapsed: $elapsed'
      ')';
}
