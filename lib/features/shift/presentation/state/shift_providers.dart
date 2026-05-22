// lib/features/shift/presentation/state/shift_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/shift_session.dart';
import '../../../../core/network/sync_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Active Shift Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the lifecycle of the currently logged-in staff member's shift.
///
/// In a production build, [build] fetches the persisted shift from local
/// storage / backend and opens a realtime subscription. Here we return a mock
/// [ShiftSession] that represents an active shift started ≈2h14m ago.
class ActiveShiftNotifier extends AsyncNotifier<ShiftSession?> {
  @override
  Future<ShiftSession?> build() async {
    // Simulate a short load delay.
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final now = DateTime.now();
    return ShiftSession(
      shiftId: 'shift-mock-001',
      staffId: 'staff-001',
      staffName: 'Ahmed Al-Rashidi',
      branchId: 'branch-downtown-01',
      status: ShiftStatus.active,
      startedAt: now.subtract(const Duration(hours: 2, minutes: 14)),
      assignedTableCount: 3,
      completedOrderCount: 14,
      activeOrderCount: 3,
      pendingCallCount: 1,
      slaComplianceRate: 0.87,
      syncState: SyncState.fresh,
    );
  }

  // ── Public mutation methods ───────────────────────────────────────────────

  /// Transitions an [ShiftStatus.idle] shift to [ShiftStatus.active].
  Future<void> startShift() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    state = AsyncValue.data(
      current.copyWith(
        status: ShiftStatus.active,
        startedAt: DateTime.now(),
        syncState: SyncState.fresh,
      ),
    );
  }

  /// Transitions an [ShiftStatus.active] shift to [ShiftStatus.paused].
  Future<void> pauseShift() async {
    final current = state.valueOrNull;
    if (current == null || current.status != ShiftStatus.active) return;

    state = AsyncValue.data(
      current.copyWith(status: ShiftStatus.paused),
    );
  }

  /// Transitions a [ShiftStatus.paused] shift back to [ShiftStatus.active].
  Future<void> resumeShift() async {
    final current = state.valueOrNull;
    if (current == null || current.status != ShiftStatus.paused) return;

    state = AsyncValue.data(
      current.copyWith(status: ShiftStatus.active),
    );
  }

  /// Closes the current shift and records the [endedAt] timestamp.
  Future<void> endShift() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data(
      current.copyWith(
        status: ShiftStatus.closed,
        endedAt: DateTime.now(),
        syncState: SyncState.stale,
      ),
    );
  }
}

/// The primary shift provider — use this anywhere the active shift is needed.
final activeShiftProvider =
    AsyncNotifierProvider<ActiveShiftNotifier, ShiftSession?>(
  ActiveShiftNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Derived Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Convenience provider that surfaces only the [ShiftStatus] from [activeShiftProvider].
/// Returns [ShiftStatus.idle] while loading or when no session exists.
final shiftStatusProvider = Provider<ShiftStatus>((ref) {
  return ref.watch(activeShiftProvider).maybeWhen(
        data: (session) => session?.status ?? ShiftStatus.idle,
        orElse: () => ShiftStatus.idle,
      );
});

/// Convenience provider that surfaces the elapsed [Duration] of the active shift.
/// Returns [Duration.zero] while loading or when no session exists.
final shiftElapsedProvider = Provider<Duration>((ref) {
  return ref.watch(activeShiftProvider).maybeWhen(
        data: (session) => session?.elapsed ?? Duration.zero,
        orElse: () => Duration.zero,
      );
});
