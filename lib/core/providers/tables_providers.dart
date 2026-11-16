// ── Tables Providers ──────────────────────────────────────────────────────────
// All tables data access goes through these providers.
// Screens MUST NOT import supabase_flutter or call Supabase.instance.client.
//
// Data flow:
//   TablesRepository (interface)
//     └─ MockTablesRepository   (kUseMockRepositories = true)
//     └─ SupabaseTablesRepository  (future, kUseMockRepositories = false)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/table_dto.dart';
import 'repository_providers.dart';
import '../auth/app_auth_provider.dart';

// ── Tables stream ─────────────────────────────────────────────────────────────
// Emits every time the underlying repository pushes an update.
final tablesStreamProvider = StreamProvider<List<RestaurantTableDto>>((
  ref,
) async* {
  final profile = await ref.watch(userProfileProvider.future);
  final tenantId = profile?['tenant_id'] as String?;
  if (tenantId == null || tenantId.isEmpty) {
    yield const [];
    return;
  }

  final repo = ref.watch(tablesRepositoryProvider);
  yield* repo.watchTables(tenantId);
});

// ── Create table ──────────────────────────────────────────────────────────────
final createTableProvider =
    Provider<Future<void> Function(RestaurantTableDto table)>((ref) {
      final repo = ref.read(tablesRepositoryProvider);
      return (table) async => repo.createTable(table);
    });

// ── Update table status ───────────────────────────────────────────────────────
final updateTableStatusProvider =
    Provider<
      Future<void> Function(
        String tableId,
        TableStatus newStatus, {
        String? activeOrderId,
      })
    >((ref) {
      final repo = ref.read(tablesRepositoryProvider);
      return (tableId, newStatus, {activeOrderId}) async => repo
          .updateTableStatus(tableId, newStatus, activeOrderId: activeOrderId);
    });

// ── Delete table ──────────────────────────────────────────────────────────────
final deleteTableProvider = Provider<Future<void> Function(String tableId)>((
  ref,
) {
  final repo = ref.read(tablesRepositoryProvider);
  return (tableId) async => repo.deleteTable(tableId);
});

// ── Realtime Table Status ─────────────────────────────────────────────────────

enum TableDiningPhase {
  vacant, // Emerald green
  seated, // Amber yellow
  cooking, // Orange KDS preparing
  dining, // Blue served
  waitingForBill, // Purple checkout requested
}

class TableStatusState {
  final TableDiningPhase phase;
  final int activeGuests;
  TableStatusState({required this.phase, required this.activeGuests});
}

TableDiningPhase _phaseFromDb(String state) {
  switch (state.toUpperCase()) {
    case 'FREE':
      return TableDiningPhase.vacant;
    case 'SEATED':
      return TableDiningPhase.seated;
    case 'COOKING':
      return TableDiningPhase.cooking;
    case 'DINING':
      return TableDiningPhase.dining;
    case 'BILL':
      return TableDiningPhase.waitingForBill;
    default:
      return TableDiningPhase.vacant;
  }
}

String _phaseToDb(TableDiningPhase phase) {
  switch (phase) {
    case TableDiningPhase.vacant:
      return 'FREE';
    case TableDiningPhase.seated:
      return 'SEATED';
    case TableDiningPhase.cooking:
      return 'COOKING';
    case TableDiningPhase.dining:
      return 'DINING';
    case TableDiningPhase.waitingForBill:
      return 'BILL';
  }
}

final tableStatusProvider = StateNotifierProvider<TableStatusNotifier, Map<String, TableStatusState>>((ref) {
  return TableStatusNotifier(ref);
});

class TableStatusNotifier extends StateNotifier<Map<String, TableStatusState>> {
  final Ref _ref;
  StreamSubscription? _subscription;

  TableStatusNotifier(this._ref) : super({}) {
    _initRealtimeStream();
  }

  void _initRealtimeStream() {
    final client = _ref.watch(supabaseClientProvider);
    final ctx = _ref.watch(appContextProvider);
    if (ctx == null) return;

    final tenantId = ctx.tenant.id;

    // 1. Fetch initial states
    client
        .from('table_runtime_projections')
        .select()
        .eq('tenant_id', tenantId)
        .then((data) {
          final newMap = <String, TableStatusState>{};
          for (final row in data) {
            final tableId = row['table_id'] as String;
            final stateStr = row['runtime_state'] as String? ?? 'FREE';
            final guests = row['active_guest_count'] as int? ?? 0;
            newMap[tableId] = TableStatusState(
              phase: _phaseFromDb(stateStr),
              activeGuests: guests,
            );
          }
          state = newMap;
        }).catchError((err) {
          debugPrint('[TableStatusNotifier] Error fetching initial states: $err');
        });

    // 2. Subscribe to realtime stream
    _subscription = client
        .from('table_runtime_projections')
        .stream(primaryKey: ['table_id'])
        .eq('tenant_id', tenantId)
        .listen((events) {
          final newMap = Map<String, TableStatusState>.from(state);
          for (final row in events) {
            final tableId = row['table_id'] as String;
            final stateStr = row['runtime_state'] as String? ?? 'FREE';
            final guests = row['active_guest_count'] as int? ?? 0;
            newMap[tableId] = TableStatusState(
              phase: _phaseFromDb(stateStr),
              activeGuests: guests,
            );
          }
          state = newMap;
        }, onError: (err) {
          debugPrint('[TableStatusNotifier] Realtime stream error: $err');
        });
  }

  TableStatusState getStatus(String tableId) {
    return state[tableId] ?? TableStatusState(phase: TableDiningPhase.vacant, activeGuests: 0);
  }

  Future<void> seatGuests(String tableId, int guests) async {
    final client = _ref.read(supabaseClientProvider);
    final ctx = _ref.read(appContextProvider);
    if (ctx == null) return;

    // Optimistic update
    state = {
      ...state,
      tableId: TableStatusState(phase: TableDiningPhase.seated, activeGuests: guests),
    };

    // Upsert database row
    await client.from('table_runtime_projections').upsert({
      'table_id': tableId,
      'tenant_id': ctx.tenant.id,
      'runtime_state': 'SEATED',
      'active_guest_count': guests,
    });
  }

  Future<void> updatePhase(String tableId, TableDiningPhase phase) async {
    final client = _ref.read(supabaseClientProvider);
    final ctx = _ref.read(appContextProvider);
    if (ctx == null) return;

    final current = getStatus(tableId);

    // Optimistic update
    state = {
      ...state,
      tableId: TableStatusState(phase: phase, activeGuests: current.activeGuests),
    };

    // Upsert database row
    await client.from('table_runtime_projections').upsert({
      'table_id': tableId,
      'tenant_id': ctx.tenant.id,
      'runtime_state': _phaseToDb(phase),
      'active_guest_count': phase == TableDiningPhase.vacant ? 0 : current.activeGuests,
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
