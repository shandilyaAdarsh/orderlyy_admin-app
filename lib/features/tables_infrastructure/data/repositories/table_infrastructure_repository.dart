import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dtos/table_dto.dart';
import '../dtos/floor_dto.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/network/dio_client.dart';

final tableInfrastructureRepositoryProvider =
    Provider<TableInfrastructureRepository>((ref) {
      final dio = ref.watch(dioClientProvider);
      return ApiTableInfrastructureRepository(dio);
    });

abstract class TableInfrastructureRepository {
  Future<List<TableDto>> getTables(String tenantId, String branchId);
  Future<TableDto> createTable(TableDto table);
  Future<TableDto> updateTable(TableDto table);
  Future<void> deleteTable(String tableId);
  Future<String> rotateQrCode(String tableId);
  Future<TableDto> generateQr(String tableId);

  // Floor management
  Future<List<FloorDto>> getFloors(String tenantId, String branchId);
  Future<FloorDto> createFloor(String branchId, String name);
  Future<void> deleteFloor(String floorId);
}

class ApiTableInfrastructureRepository
    implements TableInfrastructureRepository {
  final DioClient _dio;

  ApiTableInfrastructureRepository(this._dio);

  @override
  Future<List<TableDto>> getTables(String tenantId, String branchId) async {
    final res = await _dio.get(
      '/v1/admin/tables?branch_id=$branchId&limit=100',
    );
    final data = res.data['data'] as List;
    return data.map((json) => TableDto.fromJson(json)).toList();
  }

  @override
  Future<TableDto> createTable(TableDto table) async {
    final payload = {
      'branch_id': table.branchId,
      'table_number': table.tableNumber,
      if (table.displayName != null) 'display_name': table.displayName,
      'capacity': table.capacity,
      if (table.floorId != null && table.floorId!.isNotEmpty) 'floor_id': table.floorId,
      if (table.sectionId != null && table.sectionId!.isNotEmpty) 'section_id': table.sectionId,
    };
    final res = await _dio.post('/api/v1/admin/tables', data: payload);
    return TableDto.fromJson(res.data['data']);
  }

  @override
  Future<TableDto> updateTable(TableDto table) async {
    final payload = {
      'table_number': table.tableNumber,
      if (table.displayName != null) 'display_name': table.displayName,
      'capacity': table.capacity,
      'version_num': table.versionNum,
      if (table.floorId != null && table.floorId!.isNotEmpty) 'floor_id': table.floorId,
      if (table.sectionId != null && table.sectionId!.isNotEmpty) 'section_id': table.sectionId,
    };
    final res = await _dio.patch(
      '/api/v1/admin/tables/${table.id}',
      data: payload,
    );
    return TableDto.fromJson(res.data['data']);
  }

  @override
  Future<void> deleteTable(String tableId) async {
    await _dio.delete('/api/v1/admin/tables/$tableId');
  }

  @override
  Future<String> rotateQrCode(String tableId) async {
    final res = await _dio.post('/api/v1/admin/tables/$tableId/qr/rotate');
    return res.data['token'] as String;
  }

  @override
  Future<TableDto> generateQr(String tableId) async {
    final res = await _dio.post('/api/v1/admin/tables/$tableId/generate-qr');
    return TableDto.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // Floors implementation
  @override
  Future<List<FloorDto>> getFloors(String tenantId, String branchId) async {
    final res = await _dio.get('/api/v1/admin/tables/floors?branch_id=$branchId');
    final data = res.data['data'] as List;
    return data.map((json) => FloorDto.fromJson(json)).toList();
  }

  @override
  Future<FloorDto> createFloor(String branchId, String name) async {
    final payload = {
      'branch_id': branchId,
      'name': name,
    };
    final res = await _dio.post('/api/v1/admin/tables/floors', data: payload);
    return FloorDto.fromJson(res.data['data']);
  }

  @override
  Future<void> deleteFloor(String floorId) async {
    await _dio.delete('/api/v1/admin/tables/floors/$floorId');
  }
}
