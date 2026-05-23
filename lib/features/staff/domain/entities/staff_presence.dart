// lib/features/staff/domain/entities/staff_presence.dart

import '../../../../core/network/sync_state.dart';

/// Real-time availability status for a single staff member.
enum StaffPresenceStatus { online, busy, away, offline, onBreak, closingShift }

/// Immutable value object that represents a staff member's live presence record.
class StaffPresenceRecord {
  final String staffId;
  final String name;

  /// Human-readable role label: 'Waiter' | 'Supervisor' | 'Manager'.
  final String role;

  final StaffPresenceStatus status;

  /// The section this staff member is currently assigned to (nullable).
  final String? sectionId;
  final String? sectionLabel;

  final int activeTableCount;

  /// SLA compliance rate in the range 0.0–1.0.
  final double slaComplianceRate;

  final DateTime lastHeartbeat;
  final SyncState syncState;

  const StaffPresenceRecord({
    required this.staffId,
    required this.name,
    required this.role,
    required this.status,
    this.sectionId,
    this.sectionLabel,
    required this.activeTableCount,
    required this.slaComplianceRate,
    required this.lastHeartbeat,
    this.syncState = SyncState.unknown,
  });

  /// Returns true when the member can actively receive orders.
  bool get isOnline =>
      status == StaffPresenceStatus.online ||
      status == StaffPresenceStatus.busy;

  /// Returns true when the member is handling more than 5 tables simultaneously.
  bool get isOverloaded => activeTableCount > 5;

  StaffPresenceRecord copyWith({
    String? staffId,
    String? name,
    String? role,
    StaffPresenceStatus? status,
    String? sectionId,
    String? sectionLabel,
    int? activeTableCount,
    double? slaComplianceRate,
    DateTime? lastHeartbeat,
    SyncState? syncState,
  }) {
    return StaffPresenceRecord(
      staffId: staffId ?? this.staffId,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      sectionId: sectionId ?? this.sectionId,
      sectionLabel: sectionLabel ?? this.sectionLabel,
      activeTableCount: activeTableCount ?? this.activeTableCount,
      slaComplianceRate: slaComplianceRate ?? this.slaComplianceRate,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      syncState: syncState ?? this.syncState,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffPresenceRecord &&
          runtimeType == other.runtimeType &&
          staffId == other.staffId &&
          name == other.name &&
          role == other.role &&
          status == other.status &&
          sectionId == other.sectionId &&
          sectionLabel == other.sectionLabel &&
          activeTableCount == other.activeTableCount &&
          slaComplianceRate == other.slaComplianceRate &&
          lastHeartbeat == other.lastHeartbeat &&
          syncState == other.syncState;

  @override
  int get hashCode => Object.hash(
        staffId,
        name,
        role,
        status,
        sectionId,
        sectionLabel,
        activeTableCount,
        slaComplianceRate,
        lastHeartbeat,
        syncState,
      );

  @override
  String toString() => 'StaffPresenceRecord('
      'staffId: $staffId, '
      'name: $name, '
      'role: $role, '
      'status: $status, '
      'tables: $activeTableCount'
      ')';
}
