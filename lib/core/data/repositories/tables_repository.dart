// ── TablesRepository interface ─────────────────────────────────────────────────
// The UI layer ONLY depends on this contract.
// Implementations: MockTablesRepository (dev) | SupabaseTablesRepository (prod)

import '../dtos/table_dto.dart';

abstract class TablesRepository {
  // ── Fetch tables ──────────────────────────────────────────────────────────
  Future<List<RestaurantTableDto>> getTables(String tenantId);

  Future<RestaurantTableDto?> getTableById(String tableId);

  // ── Mutations ─────────────────────────────────────────────────────────────
  Future<RestaurantTableDto> createTable(RestaurantTableDto table);

  Future<RestaurantTableDto> updateTableStatus(
    String tableId,
    TableStatus newStatus, {
    String? activeOrderId,
  });

  Future<void> deleteTable(String tableId);

  // ── Realtime-like stream (fake events in mock) ────────────────────────────
  Stream<List<RestaurantTableDto>> watchTables(String tenantId);
}
