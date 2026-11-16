import '../dtos/staff_dto.dart';
import '../repositories/staff_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiStaffRepository implements StaffRepository {
  final DioClient _dioClient;
  final SupabaseClient _supabaseClient;

  ApiStaffRepository(this._dioClient, this._supabaseClient);

  @override
  Future<List<StaffDto>> getStaff(String tenantId) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/tenants/$tenantId/staff',
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data
            .map((json) => StaffDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          message: response.data['error']?['message'] ?? 'Failed to fetch staff',
          code: ApiErrorCode.serverError,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), code: ApiErrorCode.unknown);
    }
  }


  @override
  Future<StaffDto> createStaff(StaffDto staff) async {
    try {
      final response = await _dioClient.post(
        '/api/v1/tenants/${staff.tenantId}/staff',
        data: staff.toJson(),
      );

      if (response.data['success'] == true) {
        return StaffDto.fromJson(response.data['data']);
      } else {
        throw ApiException(
          message: response.data['error']?['message'] ?? 'Failed to create staff',
          code: ApiErrorCode.serverError,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), code: ApiErrorCode.unknown);
    }
  }

  @override
  Future<StaffDto> updateStaff(StaffDto staff) async {
    try {
      // Only send mutable fields accepted by UpdateStaffSchema
      final updatePayload = {
        'name': staff.name,
        'role': staff.role.name,
        'pin': staff.pin,
        'is_active': staff.isActive,
        'employee_id': staff.employeeId,
        'branch_id': staff.branchId,
        'email': staff.email,
      };

      final response = await _dioClient.patch(
        '/api/v1/tenants/${staff.tenantId}/staff/${staff.id}',
        data: updatePayload,
      );

      if (response.data['success'] == true) {
        return StaffDto.fromJson(response.data['data']);
      } else {
        throw ApiException(
          message: response.data['error']?['message'] ?? 'Failed to update staff',
          code: ApiErrorCode.serverError,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), code: ApiErrorCode.unknown);
    }
  }

  @override
  Future<void> deleteStaff(String tenantId, String staffId) async {
    try {
      final response = await _dioClient.delete('/api/v1/tenants/$tenantId/staff/$staffId');

      if (response.data['success'] != true) {
        throw ApiException(
          message: response.data['error']?['message'] ?? 'Failed to delete staff',
          code: ApiErrorCode.serverError,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), code: ApiErrorCode.unknown);
    }
  }

  @override
  Stream<List<StaffDto>> watchStaff(String tenantId) {
    return _supabaseClient
        .from('staff')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .map((records) => records.map((json) => StaffDto.fromJson(json)).toList());
  }
}
