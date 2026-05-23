// ── MockTablesRepository ──────────────────────────────────────────────────────
// Full mock implementation of TablesRepository.
// • Loads from tables_fixtures.json on first access (lazy).
// • Status mutations update in-memory state and push to stream.
// • watchTables() simulates realtime by emitting on every mutation.
//
// MIGRATION PATH: Replace MockTablesRepository with SupabaseTablesRepository
// in repository_providers.dart. Zero UI changes required.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../repositories/tables_repository.dart';
import '../dtos/table_dto.dart';
import '../../network/local_sync_client.dart';

class MockTablesRepository implements TablesRepository {
  List<RestaurantTableDto>? _tables;
  final _tablesController =
      StreamController<List<RestaurantTableDto>>.broadcast();

  // ── Lazy fixture loader ───────────────────────────────────────────────────
  Future<void> _ensureLoaded() async {
    if (_tables != null) return;
    final raw = await rootBundle.loadString(
      'lib/core/data/mock/fixtures/tables_fixtures.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _tables = (json['tables'] as List)
        .map((e) => RestaurantTableDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _broadcast() => _tablesController.add(List.from(_tables!));

  // ── Fetch tables ──────────────────────────────────────────────────────────
  @override
  Future<List<RestaurantTableDto>> getTables(String tenantId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    await _ensureLoaded();
    return _tables!.where((t) => t.tenantId == tenantId).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  @override
  Future<RestaurantTableDto?> getTableById(String tableId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _ensureLoaded();
    try {
      return _tables!.firstWhere((t) => t.id == tableId);
    } catch (_) {
      return null;
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────
  @override
  Future<RestaurantTableDto> createTable(RestaurantTableDto table) async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _ensureLoaded();
    _tables!.add(table);
    _broadcast();
    LocalSyncClient().broadcastEvent('table_update', table.toJson());
    return table;
  }

  @override
  Future<RestaurantTableDto> updateTableStatus(
    String tableId,
    TableStatus newStatus, {
    String? activeOrderId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    await _ensureLoaded();
    final idx = _tables!.indexWhere((t) => t.id == tableId);
    if (idx == -1) throw Exception('Table not found: $tableId');

    final updated = _tables![idx].copyWith(
      status: newStatus,
      activeOrderId: activeOrderId,
      updatedAt: DateTime.now(),
    );
    _tables![idx] = updated;
    _broadcast();
    LocalSyncClient().broadcastEvent('table_update', updated.toJson());
    return updated;
  }

  @override
  Future<void> deleteTable(String tableId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _ensureLoaded();
    _tables!.removeWhere((t) => t.id == tableId);
    _broadcast();
    LocalSyncClient().broadcastEvent('table_delete', {'id': tableId});
  }

  // ── Realtime-like stream ──────────────────────────────────────────────────
  @override
  Stream<List<RestaurantTableDto>> watchTables(String tenantId) async* {
    await _ensureLoaded();
    yield _tables!.where((t) => t.tenantId == tenantId).toList();
    yield* _tablesController.stream.map(
      (tables) => tables.where((t) => t.tenantId == tenantId).toList(),
    );
  }
}
