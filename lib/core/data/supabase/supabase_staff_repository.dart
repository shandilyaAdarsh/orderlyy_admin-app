import 'package:supabase_flutter/supabase_flutter.dart';
import '../dtos/staff_dto.dart';
import '../repositories/staff_repository.dart';

class SupabaseStaffRepository implements StaffRepository {
  final SupabaseClient _client;

  const SupabaseStaffRepository(this._client);

  @override
  Future<List<StaffDto>> getStaff(String tenantId) async {
    final response = await _client
        .from('staff')
        .select()
        .eq('tenant_id', tenantId)
        .order('name', ascending: true);

    return (response as List).map((json) => StaffDto.fromJson(json)).toList();
  }

  @override
  Future<StaffDto?> getStaffById(String staffId) async {
    final response = await _client
        .from('staff')
        .select()
        .eq('id', staffId)
        .maybeSingle();

    if (response == null) return null;
    return StaffDto.fromJson(response);
  }

  @override
  Future<StaffDto> createStaff(StaffDto staff) async {
    final response = await _client
        .from('staff')
        .insert(staff.toJson())
        .select()
        .single();

    return StaffDto.fromJson(response);
  }

  @override
  Future<StaffDto> updateStaff(StaffDto staff) async {
    final response = await _client
        .from('staff')
        .update(staff.toJson())
        .eq('id', staff.id)
        .select()
        .single();

    return StaffDto.fromJson(response);
  }

  @override
  Future<void> deleteStaff(String staffId) async {
    await _client.from('staff').delete().eq('id', staffId);
  }

  @override
  Stream<List<StaffDto>> watchStaff(String tenantId) {
    return _client
        .from('staff')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .order('name', ascending: true)
        .map((event) => event.map((json) => StaffDto.fromJson(json)).toList());
  }
}
