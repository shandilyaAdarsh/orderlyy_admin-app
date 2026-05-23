// lib/features/manager/domain/entities/staff_performance.dart

enum OverloadLevel { none, elevated, critical }

class StaffPerformanceRecord {
  final String staffId;
  final String name;
  final String role;
  final int handledOrderCount;
  final double avgOrderCompletionMinutes;
  final double avgCallResponseSeconds;
  final double slaComplianceRate; // 0.0–1.0
  final int activeTableCount;
  final String? sectionLabel;

  const StaffPerformanceRecord({
    required this.staffId,
    required this.name,
    required this.role,
    required this.handledOrderCount,
    required this.avgOrderCompletionMinutes,
    required this.avgCallResponseSeconds,
    required this.slaComplianceRate,
    required this.activeTableCount,
    this.sectionLabel,
  });

  StaffPerformanceRecord copyWith({
    String? staffId,
    String? name,
    String? role,
    int? handledOrderCount,
    double? avgOrderCompletionMinutes,
    double? avgCallResponseSeconds,
    double? slaComplianceRate,
    int? activeTableCount,
    String? sectionLabel,
    bool clearSectionLabel = false,
  }) {
    return StaffPerformanceRecord(
      staffId: staffId ?? this.staffId,
      name: name ?? this.name,
      role: role ?? this.role,
      handledOrderCount: handledOrderCount ?? this.handledOrderCount,
      avgOrderCompletionMinutes:
          avgOrderCompletionMinutes ?? this.avgOrderCompletionMinutes,
      avgCallResponseSeconds:
          avgCallResponseSeconds ?? this.avgCallResponseSeconds,
      slaComplianceRate: slaComplianceRate ?? this.slaComplianceRate,
      activeTableCount: activeTableCount ?? this.activeTableCount,
      sectionLabel: clearSectionLabel ? null : sectionLabel ?? this.sectionLabel,
    );
  }

  /// True when staff member has more than 5 active tables.
  bool get isOverloaded => activeTableCount > 5;

  /// Tiered overload assessment.
  OverloadLevel get overloadLevel {
    if (activeTableCount > 8) return OverloadLevel.critical;
    if (activeTableCount > 5) return OverloadLevel.elevated;
    return OverloadLevel.none;
  }

  /// SLA compliance as a display percentage (0–100).
  int get slaPercent => (slaComplianceRate * 100).round().clamp(0, 100);

  /// True when SLA compliance is below warning threshold (< 80%).
  bool get isSlaWarning => slaComplianceRate < 0.80;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StaffPerformanceRecord &&
        other.staffId == staffId &&
        other.name == name &&
        other.role == role &&
        other.handledOrderCount == handledOrderCount &&
        other.avgOrderCompletionMinutes == avgOrderCompletionMinutes &&
        other.avgCallResponseSeconds == avgCallResponseSeconds &&
        other.slaComplianceRate == slaComplianceRate &&
        other.activeTableCount == activeTableCount &&
        other.sectionLabel == sectionLabel;
  }

  @override
  int get hashCode => Object.hash(
        staffId,
        name,
        role,
        handledOrderCount,
        avgOrderCompletionMinutes,
        avgCallResponseSeconds,
        slaComplianceRate,
        activeTableCount,
        sectionLabel,
      );

  @override
  String toString() =>
      'StaffPerformanceRecord($name, role: $role, tables: $activeTableCount, '
      'SLA: $slaPercent%, overload: $overloadLevel)';
}
