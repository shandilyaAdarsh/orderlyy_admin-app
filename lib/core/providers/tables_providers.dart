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
import '../data/dtos/auth_dto.dart';
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
  final String? rawState;
  final DateTime? sessionOpenedAt;
  final String? assignedStaffName;
  final String? activeOrderStatus;
  final int activeOrderCount;

  TableStatusState({
    required this.phase,
    required this.activeGuests,
    this.rawState,
    this.sessionOpenedAt,
    this.assignedStaffName,
    this.activeOrderStatus,
    this.activeOrderCount = 0,
  });

  String get sessionDurationDisplay {
    if (phase == TableDiningPhase.vacant || sessionOpenedAt == null) {
      return 'No active session';
    }
    final diff = DateTime.now().toUtc().difference(sessionOpenedAt!.toUtc());
    final mins = diff.inMinutes;
    if (mins < 1) return '< 1m elapsed';
    if (mins < 60) return '${mins}m elapsed';
    final hours = diff.inHours;
    final remMins = mins % 60;
    return '${hours}h ${remMins}m elapsed';
  }

  String get diningStatusDisplay {
    if (phase == TableDiningPhase.vacant) {
      return 'Vacant';
    }
    if (phase == TableDiningPhase.waitingForBill) {
      return 'Bill Requested';
    }
    if (activeOrderStatus != null && activeOrderStatus!.isNotEmpty) {
      switch (activeOrderStatus!.toLowerCase()) {
        case 'preparing':
          return 'Preparing in Kitchen';
        case 'ready':
          return 'Order Ready to Serve';
        case 'delivered':
        case 'completed':
          return 'Served & Dining';
        case 'pending':
        case 'accepted':
          return 'Order Placed';
        default:
          return activeOrderStatus!.toUpperCase();
      }
    }
    if (phase == TableDiningPhase.seated) {
      return 'Browsing Menu';
    }
    if (phase == TableDiningPhase.cooking) {
      return 'Preparing Order';
    }
    if (phase == TableDiningPhase.dining) {
      return 'Served & Dining';
    }
    return 'Active';
  }

  String get waiterDisplay {
    if (assignedStaffName != null && assignedStaffName!.trim().isNotEmpty) {
      return assignedStaffName!;
    }
    return 'Unassigned';
  }
}

TableDiningPhase _phaseFromDb(String state) {
  switch (state.toUpperCase()) {
    case 'FREE':
    case 'AVAILABLE':
      return TableDiningPhase.vacant;
    case 'SEATED':
    case 'ACTIVE_GUESTS':
      return TableDiningPhase.seated;
    case 'ORDERING':
    case 'COOKING':
    case 'PREPARING':
      return TableDiningPhase.cooking;
    case 'DINING':
    case 'SERVED':
    case 'DELIVERED':
      return TableDiningPhase.dining;
    case 'BILL':
    case 'PAYMENT_PENDING':
    case 'ASSISTANCE_REQUESTED':
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
      return 'ACTIVE_GUESTS';
    case TableDiningPhase.cooking:
      return 'ORDERING';
    case TableDiningPhase.dining:
      return 'DELIVERED';
    case TableDiningPhase.waitingForBill:
      return 'PAYMENT_PENDING';
  }
}

final tableStatusProvider =
    StateNotifierProvider<TableStatusNotifier, Map<String, TableStatusState>>((ref) {
  final ctx = ref.watch(appContextProvider);
  return TableStatusNotifier(ref, ctx);
});

class TableStatusNotifier extends StateNotifier<Map<String, TableStatusState>> {
  final Ref _ref;
  final AppContextDto? _ctx;
  StreamSubscription? _projSubscription;
  StreamSubscription? _sessionsSubscription;
  StreamSubscription? _ordersSubscription;
  StreamSubscription? _tablesSubscription;

  TableStatusNotifier(this._ref, this._ctx) : super({}) {
    if (_ctx != null) {
      _initRealtimeStream();
    }
  }

  void _initRealtimeStream() {
    if (_ctx == null) return;
    final tenantId = _ctx.tenant.id;
    final client = _ref.read(supabaseClientProvider);

    _fetchFullState();

    // 1. Projections stream
    _projSubscription = client
        .from('table_runtime_projections')
        .stream(primaryKey: ['table_id'])
        .eq('tenant_id', tenantId)
        .listen((_) => _fetchFullState(), onError: (err) {
          debugPrint('[TableStatusNotifier] Projections stream error: $err');
        });

    // 2. Table sessions stream
    _sessionsSubscription = client
        .from('table_sessions')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .listen((_) => _fetchFullState(), onError: (err) {
          debugPrint('[TableStatusNotifier] Sessions stream error: $err');
        });

    // 3. Orders stream
    _ordersSubscription = client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .listen((_) => _fetchFullState(), onError: (err) {
          debugPrint('[TableStatusNotifier] Orders stream error: $err');
        });

    // 4. Tables stream
    _tablesSubscription = client
        .from('tables')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .listen((_) => _fetchFullState(), onError: (err) {
          debugPrint('[TableStatusNotifier] Tables stream error: $err');
        });
  }

  Future<void> _fetchFullState() async {
    if (_ctx == null) return;
    final tenantId = _ctx.tenant.id;
    final client = _ref.read(supabaseClientProvider);

    try {
      final tablesRes = await client
          .from('tables')
          .select('id, table_number, capacity, assigned_staff_id, current_session_id, status, staff:assigned_staff_id(name)')
          .eq('tenant_id', tenantId);

      final sessionsRes = await client
          .from('table_sessions')
          .select('id, table_id, status, opened_at')
          .eq('tenant_id', tenantId)
          .eq('status', 'open');

      final ordersRes = await client
          .from('orders')
          .select('id, table_id, status, created_at')
          .eq('tenant_id', tenantId)
          .not('status', 'in', '("completed","cancelled")');

      final projRes = await client
          .from('table_runtime_projections')
          .select()
          .eq('tenant_id', tenantId);

      final openSessionsMap = <String, Map<String, dynamic>>{};
      for (final s in (sessionsRes as List)) {
        final tid = s['table_id'] as String?;
        if (tid != null) {
          openSessionsMap[tid] = Map<String, dynamic>.from(s as Map);
        }
      }

      final activeOrdersMap = <String, Map<String, dynamic>>{};
      for (final o in (ordersRes as List)) {
        final tid = o['table_id'] as String?;
        if (tid != null && !activeOrdersMap.containsKey(tid)) {
          activeOrdersMap[tid] = Map<String, dynamic>.from(o as Map);
        }
      }

      final staffNameMap = <String, String>{};
      final tableStatusMap = <String, String>{};
      for (final t in (tablesRes as List)) {
        final tid = t['id'] as String;
        final staff = t['staff'] as Map<String, dynamic>?;
        if (staff != null && staff['name'] != null) {
          staffNameMap[tid] = staff['name'].toString();
        }
        if (t['status'] != null) {
          tableStatusMap[tid] = t['status'].toString();
        }
      }

      final newMap = <String, TableStatusState>{};
      for (final row in (projRes as List)) {
        final tableId = row['table_id'] as String;
        final stateStr = row['runtime_state'] as String? ?? 'FREE';
        final guests = row['active_guest_count'] as int? ?? 0;
        final session = openSessionsMap[tableId];
        final order = activeOrdersMap[tableId];
        final staffName = staffNameMap[tableId];

        DateTime? sessionOpenedAt;
        if (session != null && session['opened_at'] != null) {
          sessionOpenedAt = DateTime.tryParse(session['opened_at'].toString());
        }

        TableDiningPhase phase = _phaseFromDb(stateStr);
        if (phase == TableDiningPhase.vacant && (session != null || tableStatusMap[tableId] == 'occupied')) {
          phase = TableDiningPhase.seated;
        }

        newMap[tableId] = TableStatusState(
          phase: phase,
          activeGuests: guests > 0 ? guests : (session != null ? 1 : 0),
          rawState: stateStr,
          sessionOpenedAt: sessionOpenedAt,
          assignedStaffName: staffName,
          activeOrderStatus: order?['status']?.toString(),
          activeOrderCount: order != null ? 1 : 0,
        );
      }

      for (final t in (tablesRes as List)) {
        final tableId = t['id'] as String;
        if (!newMap.containsKey(tableId)) {
          final session = openSessionsMap[tableId];
          final order = activeOrdersMap[tableId];
          final staffName = staffNameMap[tableId];
          DateTime? sessionOpenedAt;
          if (session != null && session['opened_at'] != null) {
            sessionOpenedAt = DateTime.tryParse(session['opened_at'].toString());
          }
          final isOccupied = t['status'] == 'occupied' || session != null;
          newMap[tableId] = TableStatusState(
            phase: isOccupied ? TableDiningPhase.seated : TableDiningPhase.vacant,
            activeGuests: session != null ? 1 : 0,
            rawState: isOccupied ? 'SEATED' : 'FREE',
            sessionOpenedAt: sessionOpenedAt,
            assignedStaffName: staffName,
            activeOrderStatus: order?['status']?.toString(),
            activeOrderCount: order != null ? 1 : 0,
          );
        }
      }

      state = newMap;
    } catch (err) {
      debugPrint('[TableStatusNotifier] Error fetching full state: $err');
    }
  }

  TableStatusState getStatus(String tableId) {
    return state[tableId] ??
        TableStatusState(phase: TableDiningPhase.vacant, activeGuests: 0);
  }

  Future<void> seatGuests(String tableId, int guests) async {
    final client = _ref.read(supabaseClientProvider);
    if (_ctx == null) return;

    final existingSession = await client
        .from('table_sessions')
        .select('id')
        .eq('table_id', tableId)
        .eq('status', 'open')
        .maybeSingle();

    if (existingSession == null) {
      await client.from('table_sessions').insert({
        'tenant_id': _ctx.tenant.id,
        'table_id': tableId,
        'status': 'open',
        'opened_at': DateTime.now().toUtc().toIso8601String(),
      });
      await client.from('tables').update({
        'status': 'occupied',
      }).eq('id', tableId);
    }

    await client.from('table_runtime_projections').upsert({
      'table_id': tableId,
      'tenant_id': _ctx.tenant.id,
      'runtime_state': 'ACTIVE_GUESTS',
      'active_guest_count': guests,
    });

    await _fetchFullState();
  }

  Future<void> updatePhase(String tableId, TableDiningPhase phase) async {
    final client = _ref.read(supabaseClientProvider);
    if (_ctx == null) return;

    if (phase == TableDiningPhase.vacant) {
      await client.from('table_sessions').update({
        'status': 'closed',
        'closed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('table_id', tableId).eq('status', 'open');

      await client.from('tables').update({
        'status': 'available',
        'current_session_id': null,
      }).eq('id', tableId);

      await client.from('table_runtime_projections').upsert({
        'table_id': tableId,
        'tenant_id': _ctx.tenant.id,
        'runtime_state': 'FREE',
        'active_guest_count': 0,
        'active_order_count': 0,
      });
    } else {
      final current = getStatus(tableId);
      await client.from('table_runtime_projections').upsert({
        'table_id': tableId,
        'tenant_id': _ctx.tenant.id,
        'runtime_state': _phaseToDb(phase),
        'active_guest_count': current.activeGuests > 0 ? current.activeGuests : 1,
      });
    }

    await _fetchFullState();
  }

  @override
  void dispose() {
    _projSubscription?.cancel();
    _sessionsSubscription?.cancel();
    _ordersSubscription?.cancel();
    _tablesSubscription?.cancel();
    super.dispose();
  }
}
