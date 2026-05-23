// ── StaffRepository interface ──────────────────────────────────────────────────
// The UI layer ONLY depends on this contract.
// Implementations: MockStaffRepository (dev) | SupabaseStaffRepository (prod)

import '../dtos/staff_dto.dart';

abstract class StaffRepository {
  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<List<StaffDto>> getStaff(String tenantId);

  Future<StaffDto?> getStaffById(String staffId);

  // ── Mutations ─────────────────────────────────────────────────────────────
  Future<StaffDto> createStaff(StaffDto staff);

  Future<StaffDto> updateStaff(StaffDto staff);

  Future<void> deleteStaff(String staffId);

  // ── Realtime-like stream ──────────────────────────────────────────────────
  Stream<List<StaffDto>> watchStaff(String tenantId);
}
