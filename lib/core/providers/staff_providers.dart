// ── Staff Providers ───────────────────────────────────────────────────────────
// All staff data access goes through these providers.
// Screens MUST NOT import supabase_flutter or call Supabase.instance.client.
//
// Data flow:
//   StaffRepository (interface)
//     └─ MockStaffRepository   (kUseMockRepositories = true)
//     └─ SupabaseStaffRepository  (future, kUseMockRepositories = false)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/staff_dto.dart';
import 'repository_providers.dart';

import '../auth/mock_auth_provider.dart';
import '../runtime/runtime_context.dart';

// ── Staff stream ──────────────────────────────────────────────────────────────
// Emits every time the underlying repository pushes an update.
final staffStreamProvider = StreamProvider<List<StaffDto>>((ref) async* {
  final profile = await ref.watch(userProfileProvider.future);
  final tenantId = requireContextValue(
    value: profile?['tenant_id'] as String?,
    field: 'tenantId',
    source: 'staffStreamProvider',
  );

  final repo = ref.watch(staffRepositoryProvider);
  yield* repo.watchStaff(tenantId);
});

// ── Create staff ──────────────────────────────────────────────────────────────
final createStaffProvider = Provider<Future<void> Function(StaffDto staff)>((
  ref,
) {
  final repo = ref.read(staffRepositoryProvider);
  return (staff) async => repo.createStaff(staff);
});

// ── Update staff ──────────────────────────────────────────────────────────────
final updateStaffProvider = Provider<Future<void> Function(StaffDto staff)>((
  ref,
) {
  final repo = ref.read(staffRepositoryProvider);
  return (staff) async => repo.updateStaff(staff);
});

// ── Delete staff ──────────────────────────────────────────────────────────────
final deleteStaffProvider = Provider<Future<void> Function(String staffId)>((
  ref,
) {
  final repo = ref.read(staffRepositoryProvider);
  return (staffId) async => repo.deleteStaff(staffId);
});
