// ── MockAuthRepository ────────────────────────────────────────────────────────
// Full mock implementation of AuthRepository.
// • Any email + password >= 6 chars succeeds.
// • Staff PIN lookup is against the static fixture map.
// • resolveContext() returns the hardcoded mock AppContextDto.
// • Sign-out clears the in-memory session.
//
// MIGRATION PATH: Replace MockAuthRepository with SupabaseAuthRepository
// in repository_providers.dart. Zero UI changes required.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../repositories/auth_repository.dart';
import '../dtos/auth_dto.dart';

class MockAuthRepository implements AuthRepository {
  // ── In-memory session ─────────────────────────────────────────────────────
  String? _currentUserId;
  final _authStateController = StreamController<String?>.broadcast();

  // ── Auth state stream ─────────────────────────────────────────────────────
  @override
  Stream<String?> get authStateStream => _authStateController.stream;

  @override
  String? get currentUserId => _currentUserId;

  // ── Email + password sign-in ──────────────────────────────────────────────
  @override
  Future<LoginResponseDto> signInWithPassword(
    LoginRequestDto request,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (request.email.isEmpty || !request.email.contains('@')) {
      return LoginResponseDto.failure('Invalid email address.');
    }
    if (request.password.length < 6) {
      return LoginResponseDto.failure('Password must be at least 6 characters.');
    }

    // Accept any valid-format credentials in mock mode
    _currentUserId = 'mock-user-admin-001';
    _authStateController.add(_currentUserId);

    return LoginResponseDto(
      userId: _currentUserId!,
      email: request.email,
      accessToken: 'mock-access-token-dev',
      isSuccess: true,
    );
  }

  // ── Staff PIN sign-in ─────────────────────────────────────────────────────
  @override
  Future<StaffPinLoginResponseDto> staffPinLogin(
    StaffPinLoginRequestDto request,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final raw = await rootBundle.loadString(
      'lib/core/data/mock/fixtures/auth_fixtures.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final pins = (json['mock_credentials']['staff_pins'] as List)
        .cast<Map<String, dynamic>>();

    final match = pins.where((p) =>
        p['pin'] == request.pin &&
        p['tenant_slug'] == request.tenantSlug).firstOrNull;

    if (match == null) {
      return StaffPinLoginResponseDto.failure('Invalid PIN or restaurant code.');
    }

    final staffDto = StaffDto(
      id: 'staff-${match['role']}-001',
      name: match['name'] as String,
      role: match['role'] as String,
      tenantId: 'mock-tenant-001',
      tenantName: 'The Spice Garden',
      tenantSlug: match['tenant_slug'] as String,
      isActive: true,
    );

    _currentUserId = staffDto.id;
    _authStateController.add(_currentUserId);

    return StaffPinLoginResponseDto(isSuccess: true, staff: staffDto);
  }

  // ── Resolve app context ───────────────────────────────────────────────────
  @override
  Future<AppContextDto?> resolveContext() async {
    await Future.delayed(const Duration(milliseconds: 400));

    final raw = await rootBundle.loadString(
      'lib/core/data/mock/fixtures/auth_fixtures.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AppContextDto.fromJson(
      json['context'] as Map<String, dynamic>,
    );
  }

  // ── Change password ───────────────────────────────────────────────────────
  @override
  Future<void> changePassword(String email, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // No-op in mock — just simulates success
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUserId = null;
    _authStateController.add(null);
  }
}
