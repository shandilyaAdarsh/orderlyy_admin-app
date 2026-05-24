// ── Tables Providers ──────────────────────────────────────────────────────────
// All tables data access goes through these providers.
// Screens MUST NOT import supabase_flutter or call Supabase.instance.client.
//
// Data flow:
//   TablesRepository (interface)
//     └─ MockTablesRepository   (kUseMockRepositories = true)
//     └─ SupabaseTablesRepository  (future, kUseMockRepositories = false)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/table_dto.dart';
import 'repository_providers.dart';

import '../auth/mock_auth_provider.dart';
import '../runtime/runtime_context.dart';

// ── Tables stream ─────────────────────────────────────────────────────────────
// Emits every time the underlying repository pushes an update.
final tablesStreamProvider = StreamProvider<List<RestaurantTableDto>>((
  ref,
) async* {
  final profile = await ref.watch(userProfileProvider.future);
  final tenantId = requireContextValue(
    value: profile?['tenant_id'] as String?,
    field: 'tenantId',
    source: 'tablesStreamProvider',
  );

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
