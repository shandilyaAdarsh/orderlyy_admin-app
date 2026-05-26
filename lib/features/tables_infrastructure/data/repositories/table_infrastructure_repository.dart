import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orderlli_admin/features/tables_infrastructure/data/dtos/table_dto.dart';

final tableInfrastructureRepositoryProvider = Provider<TableInfrastructureRepository>((ref) {
  return MockTableInfrastructureRepository();
});

abstract class TableInfrastructureRepository {
  Future<List<TableDto>> getTables(String tenantId, String branchId);
  Future<TableDto> createTable(TableDto table);
  Future<TableDto> updateTable(TableDto table);
  Future<void> deleteTable(String tableId);
  Future<String> rotateQrCode(String tableId);
}

class MockTableInfrastructureRepository implements TableInfrastructureRepository {
  final List<TableDto> _tables = [
    TableDto(
      id: 'tbl_1',
      tenantId: 'tenant_1',
      branchId: 'branch_1',
      label: '1',
      capacity: 4,
      qrCodeToken: 'tok_1',
      sectionId: 'sec_1',
      isActive: true,
      createdAt: DateTime.now(),
    ),
    TableDto(
      id: 'tbl_2',
      tenantId: 'tenant_1',
      branchId: 'branch_1',
      label: '2',
      capacity: 2,
      qrCodeToken: 'tok_2',
      sectionId: 'sec_1',
      isActive: true,
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<TableDto>> getTables(String tenantId, String branchId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _tables.where((t) => t.tenantId == tenantId && t.branchId == branchId).toList();
  }

  @override
  Future<TableDto> createTable(TableDto table) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tables.add(table);
    return table;
  }

  @override
  Future<TableDto> updateTable(TableDto table) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tables.indexWhere((t) => t.id == table.id);
    if (index >= 0) {
      _tables[index] = table;
    }
    return table;
  }

  @override
  Future<void> deleteTable(String tableId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tables.removeWhere((t) => t.id == tableId);
  }

  @override
  Future<String> rotateQrCode(String tableId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index >= 0) {
      final newToken = 'tok_${DateTime.now().millisecondsSinceEpoch}';
      _tables[index] = _tables[index].copyWith(qrCodeToken: newToken);
      return newToken;
    }
    throw Exception('Table not found');
  }
}
