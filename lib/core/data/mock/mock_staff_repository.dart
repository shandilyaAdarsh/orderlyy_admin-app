// ── MockStaffRepository ───────────────────────────────────────────────────────
// Full mock implementation of StaffRepository.
// • Loads from staff_fixtures.json on first access (lazy).
// • Mutations update in-memory state and push to stream.
// • watchStaff() simulates realtime by emitting on every mutation.
//
// MIGRATION PATH: Replace MockStaffRepository with SupabaseStaffRepository
// in repository_providers.dart. Zero UI changes required.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../repositories/staff_repository.dart';
import '../dtos/staff_dto.dart';

class MockStaffRepository implements StaffRepository {
  List<StaffDto>? _staff;
  final _staffController = StreamController<List<StaffDto>>.broadcast();

  // ── Lazy fixture loader ───────────────────────────────────────────────────
  Future<void> _ensureLoaded() async {
    if (_staff != null) return;
    final raw = await rootBundle.loadString(
      'lib/core/data/mock/fixtures/staff_fixtures.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _staff = (json['staff'] as List)
        .map((e) => StaffDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _broadcast() => _staffController.add(List.from(_staff!));

  // ── Fetch ─────────────────────────────────────────────────────────────────
  @override
  Future<List<StaffDto>> getStaff(String tenantId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    await _ensureLoaded();
    return _staff!.where((s) => s.tenantId == tenantId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<StaffDto?> getStaffById(String staffId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _ensureLoaded();
    try {
      return _staff!.firstWhere((s) => s.id == staffId);
    } catch (_) {
      return null;
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────
  @override
  Future<StaffDto> createStaff(StaffDto staff) async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _ensureLoaded();
    _staff!.add(staff);
    _broadcast();
    return staff;
  }

  @override
  Future<StaffDto> updateStaff(StaffDto staff) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _ensureLoaded();
    final idx = _staff!.indexWhere((s) => s.id == staff.id);
    if (idx == -1) throw Exception('Staff not found: ${staff.id}');
    _staff![idx] = staff;
    _broadcast();
    return staff;
  }

  @override
  Future<void> deleteStaff(String staffId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _ensureLoaded();
    _staff!.removeWhere((s) => s.id == staffId);
    _broadcast();
  }

  // ── Realtime-like stream ──────────────────────────────────────────────────
  @override
  Stream<List<StaffDto>> watchStaff(String tenantId) async* {
    await _ensureLoaded();
    yield _staff!.where((s) => s.tenantId == tenantId).toList();
    yield* _staffController.stream.map(
      (staff) => staff.where((s) => s.tenantId == tenantId).toList(),
    );
  }
}
