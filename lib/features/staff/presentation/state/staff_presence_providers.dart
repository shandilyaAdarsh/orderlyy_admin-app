// lib/features/staff/presentation/state/staff_presence_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/staff_presence.dart';
import '../../../../core/network/sync_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Staff Presence Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the live presence list for all staff members in the active branch.
///
/// In production, [build] would subscribe to the realtime presence channel.
/// Here we return a deterministic 6-member mock list that exercises every
/// [StaffPresenceStatus] variant and the [isOverloaded] edge case.
class StaffPresenceNotifier
    extends AsyncNotifier<List<StaffPresenceRecord>> {
  @override
  Future<List<StaffPresenceRecord>> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));

    final now = DateTime.now();

    return [
      // ── 1. Online — light load (3 tables) ─────────────────────────────────
      StaffPresenceRecord(
        staffId: 'staff-001',
        name: 'Ahmed Al-Rashidi',
        role: 'Waiter',
        status: StaffPresenceStatus.online,
        sectionId: 'section-A',
        sectionLabel: 'Main Hall — A',
        activeTableCount: 3,
        slaComplianceRate: 0.92,
        lastHeartbeat: now.subtract(const Duration(seconds: 8)),
        syncState: SyncState.fresh,
      ),

      // ── 2. Online — moderate load (5 tables) ──────────────────────────────
      StaffPresenceRecord(
        staffId: 'staff-002',
        name: 'Layla Mansoor',
        role: 'Waiter',
        status: StaffPresenceStatus.online,
        sectionId: 'section-B',
        sectionLabel: 'Main Hall — B',
        activeTableCount: 5,
        slaComplianceRate: 0.78,
        lastHeartbeat: now.subtract(const Duration(seconds: 15)),
        syncState: SyncState.fresh,
      ),

      // ── 3. Busy — overloaded (7 tables, isOverloaded == true) ─────────────
      StaffPresenceRecord(
        staffId: 'staff-003',
        name: 'Tariq Nouri',
        role: 'Waiter',
        status: StaffPresenceStatus.busy,
        sectionId: 'section-C',
        sectionLabel: 'Terrace',
        activeTableCount: 7,
        slaComplianceRate: 0.55,
        lastHeartbeat: now.subtract(const Duration(seconds: 4)),
        syncState: SyncState.fresh,
      ),

      // ── 4. Away ───────────────────────────────────────────────────────────
      StaffPresenceRecord(
        staffId: 'staff-004',
        name: 'Sara Al-Khatib',
        role: 'Supervisor',
        status: StaffPresenceStatus.away,
        activeTableCount: 0,
        slaComplianceRate: 0.88,
        lastHeartbeat: now.subtract(const Duration(minutes: 4)),
        syncState: SyncState.stale,
      ),

      // ── 5. On Break ───────────────────────────────────────────────────────
      StaffPresenceRecord(
        staffId: 'staff-005',
        name: 'Omar Haddad',
        role: 'Waiter',
        status: StaffPresenceStatus.onBreak,
        activeTableCount: 0,
        slaComplianceRate: 0.81,
        lastHeartbeat: now.subtract(const Duration(minutes: 12)),
        syncState: SyncState.stale,
      ),

      // ── 6. Offline ────────────────────────────────────────────────────────
      StaffPresenceRecord(
        staffId: 'staff-006',
        name: 'Nadia Farouk',
        role: 'Manager',
        status: StaffPresenceStatus.offline,
        activeTableCount: 0,
        slaComplianceRate: 0.95,
        lastHeartbeat: now.subtract(const Duration(hours: 1, minutes: 22)),
        syncState: SyncState.degraded,
      ),
    ];
  }

  // ── Helpers for future realtime updates ───────────────────────────────────

  /// Update the presence record for a single staff member in-place.
  Future<void> updateRecord(StaffPresenceRecord updated) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final idx = current.indexWhere((r) => r.staffId == updated.staffId);
    if (idx == -1) return;

    final next = List<StaffPresenceRecord>.from(current);
    next[idx] = updated;
    state = AsyncValue.data(next);
  }
}

/// The primary staff presence provider.
final staffPresenceProvider =
    AsyncNotifierProvider<StaffPresenceNotifier, List<StaffPresenceRecord>>(
  StaffPresenceNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Derived Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns only staff members who are currently online or busy.
final onlineStaffProvider = Provider<List<StaffPresenceRecord>>((ref) {
  return ref.watch(staffPresenceProvider).maybeWhen(
        data: (list) => list.where((r) => r.isOnline).toList(),
        orElse: () => const [],
      );
});

/// Returns only staff members whose [activeTableCount] exceeds 5.
final overloadedStaffProvider = Provider<List<StaffPresenceRecord>>((ref) {
  return ref.watch(staffPresenceProvider).maybeWhen(
        data: (list) => list.where((r) => r.isOverloaded).toList(),
        orElse: () => const [],
      );
});

/// Average occupancy ratio across online staff as a fraction of capacity.
///
/// Capacity is fixed at 6 tables per waiter — the industry standard that
/// triggers the [isOverloaded] guard. Returns 0.0 while loading.
final branchLoadPercentProvider = Provider<double>((ref) {
  const capacityPerStaff = 6;

  return ref.watch(staffPresenceProvider).maybeWhen(
        data: (list) {
          final online = list.where((r) => r.isOnline).toList();
          if (online.isEmpty) return 0.0;

          final totalTables =
              online.fold<int>(0, (sum, r) => sum + r.activeTableCount);
          final totalCapacity = online.length * capacityPerStaff;
          return (totalTables / totalCapacity).clamp(0.0, 1.0);
        },
        orElse: () => 0.0,
      );
});
