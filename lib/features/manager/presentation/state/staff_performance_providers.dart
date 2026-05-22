// lib/features/manager/presentation/state/staff_performance_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/staff_performance.dart';

// ---------------------------------------------------------------------------
// StaffPerformanceNotifier
// ---------------------------------------------------------------------------

class StaffPerformanceNotifier
    extends AsyncNotifier<List<StaffPerformanceRecord>> {
  @override
  Future<List<StaffPerformanceRecord>> build() async {
    // Simulate a brief async fetch (replace with real repository call).
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _mockRecords();
  }

  static List<StaffPerformanceRecord> _mockRecords() {
    return const [
      // High-performer — well within limits.
      StaffPerformanceRecord(
        staffId: 'staff-01',
        name: 'Aarav Mehta',
        role: 'Senior Waiter',
        handledOrderCount: 22,
        avgOrderCompletionMinutes: 14.5,
        avgCallResponseSeconds: 28.0,
        slaComplianceRate: 0.96,
        activeTableCount: 4,
        sectionLabel: 'Section A',
      ),
      // Elevated overload — 6 tables.
      StaffPerformanceRecord(
        staffId: 'staff-02',
        name: 'Ravi Kumar',
        role: 'Waiter',
        handledOrderCount: 18,
        avgOrderCompletionMinutes: 19.2,
        avgCallResponseSeconds: 42.0,
        slaComplianceRate: 0.81,
        activeTableCount: 6,
        sectionLabel: 'Section B',
      ),
      // SLA warning — slow response.
      StaffPerformanceRecord(
        staffId: 'staff-03',
        name: 'Priya Sharma',
        role: 'Waiter',
        handledOrderCount: 15,
        avgOrderCompletionMinutes: 23.8,
        avgCallResponseSeconds: 67.0,
        slaComplianceRate: 0.74,
        activeTableCount: 5,
        sectionLabel: 'Section C',
      ),
      // Critical overload — 9 tables.
      StaffPerformanceRecord(
        staffId: 'staff-04',
        name: 'Deepak Nair',
        role: 'Waiter',
        handledOrderCount: 27,
        avgOrderCompletionMinutes: 26.1,
        avgCallResponseSeconds: 55.0,
        slaComplianceRate: 0.68,
        activeTableCount: 9,
        sectionLabel: 'Section A & B',
      ),
      // Runner — no section, fewer orders.
      StaffPerformanceRecord(
        staffId: 'staff-05',
        name: 'Sneha Rao',
        role: 'Runner',
        handledOrderCount: 31,
        avgOrderCompletionMinutes: 8.4,
        avgCallResponseSeconds: 18.0,
        slaComplianceRate: 0.93,
        activeTableCount: 3,
      ),
    ];
  }

  /// Manually refresh the staff performance list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  /// Update a single record (e.g. after a realtime table-assignment event).
  void updateRecord(StaffPerformanceRecord updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.map((r) => r.staffId == updated.staffId ? updated : r).toList(),
    );
  }

  /// Increment active table count for a staff member.
  void incrementTables(String staffId) {
    _adjustTables(staffId, 1);
  }

  /// Decrement active table count for a staff member (min 0).
  void decrementTables(String staffId) {
    _adjustTables(staffId, -1);
  }

  void _adjustTables(String staffId, int delta) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.map((r) {
        if (r.staffId != staffId) return r;
        return r.copyWith(
          activeTableCount: (r.activeTableCount + delta).clamp(0, 99),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Full staff performance list (async).
final staffPerformanceListProvider = AsyncNotifierProvider<
    StaffPerformanceNotifier, List<StaffPerformanceRecord>>(
  StaffPerformanceNotifier.new,
);

/// Average SLA compliance rate across all staff (branch-level).
/// Returns 0.0 while data is loading or on error.
final branchSLAComplianceProvider = Provider<double>((ref) {
  final asyncList = ref.watch(staffPerformanceListProvider);
  return asyncList.when(
    data: (records) {
      if (records.isEmpty) return 0.0;
      final total = records.fold<double>(0.0, (sum, r) => sum + r.slaComplianceRate);
      return total / records.length;
    },
    loading: () => 0.0,
    error: (error, stackTrace) => 0.0,
  );
});

/// Average call response time in seconds across all staff (branch-level).
/// Returns 0.0 while data is loading or on error.
final branchAvgResponseTimeProvider = Provider<double>((ref) {
  final asyncList = ref.watch(staffPerformanceListProvider);
  return asyncList.when(
    data: (records) {
      if (records.isEmpty) return 0.0;
      final total =
          records.fold<double>(0.0, (sum, r) => sum + r.avgCallResponseSeconds);
      return total / records.length;
    },
    loading: () => 0.0,
    error: (error, stackTrace) => 0.0,
  );
});
