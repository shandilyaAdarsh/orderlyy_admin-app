// ── MockAuthRepository ────────────────────────────────────────────────────────
// Full mock implementation of AuthRepository.
// • Any email + password >= 6 chars succeeds.
// • Staff PIN lookup is against the static fixture map.
// • resolveContext() returns the hardcoded mock AppContextDto.
// • Session is persisted to SharedPreferences so it survives rebuilds/restarts.
//
// MIGRATION PATH: Replace MockAuthRepository with SupabaseAuthRepository
// in repository_providers.dart. Zero UI changes required.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import '../dtos/auth_dto.dart';

// ── Persistence key ───────────────────────────────────────────────────────────
const _kMockUserIdKey = 'mock_auth_user_id';
const _kMockStaffSessionKey = 'mock_auth_staff_session';

class MockAuthRepository implements AuthRepository {
  // ── Singleton Pattern ──────────────────────────────────────────────────────
  static final MockAuthRepository _instance = MockAuthRepository._internal();

  factory MockAuthRepository() {
    debugPrint(
      '[AUTH INSTANCE] [MockAuthRepository Factory] Returning singleton, hashCode=${_instance.hashCode}',
    );
    return _instance;
  }

  MockAuthRepository._internal() {
    debugPrint(
      '[AUTH INSTANCE] [MockAuthRepository Init] Created singleton instance, hashCode=$hashCode',
    );
  }

  // ── Session state — backed by SharedPreferences ───────────────────────────
  String? _currentUserId;
  StaffDto? _currentStaff;
  final _authStateController = StreamController<String?>.broadcast();

  // ── Auth state stream ─────────────────────────────────────────────────────
  @override
  Stream<String?> get authStateStream {
    debugPrint(
      '[AUTH INSTANCE] [authStateStream Read] Returning stream for hashCode=$hashCode',
    );
    return _authStateController.stream;
  }

  @override
  String? get currentUserId {
    debugPrint(
      '[AUTH INSTANCE] [currentUserId Read] userId=$_currentUserId hashCode=$hashCode',
    );
    return _currentUserId;
  }

  @override
  StaffDto? get currentStaff {
    debugPrint(
      '[AUTH INSTANCE] [currentStaff Read] staffName=${_currentStaff?.name} hashCode=$hashCode',
    );
    return _currentStaff;
  }

  // ── Restore persisted session (call once at app start) ────────────────────
  @override
  Future<void> restoreSession() async {
    debugPrint('[TRACE] [MockAuth restoreSession Start] hashCode=$hashCode');
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kMockUserIdKey);
      debugPrint('[TRACE] [MockAuth restoreSession] Read saved userId: $saved');
      if (saved != null && saved.isNotEmpty) {
        _currentUserId = saved;
        if (saved.startsWith('staff-')) {
          final staffJson = prefs.getString(_kMockStaffSessionKey);
          debugPrint(
            '[TRACE] [MockAuth restoreSession] Read saved staff JSON: $staffJson',
          );
          if (staffJson != null) {
            try {
              _currentStaff = StaffDto.fromJson(
                jsonDecode(staffJson) as Map<String, dynamic>,
              );
              debugPrint(
                '[MockAuth] ✅ Restored staff DTO: ${_currentStaff?.name}',
              );
            } catch (e) {
              debugPrint('[MockAuth] ⚠️ Failed to decode staff DTO: $e');
            }
          }
        }
        _authStateController.add(_currentUserId);
        debugPrint(
          '[MockAuth] ✅ Session restored: $_currentUserId (hashCode=$hashCode)',
        );
      } else {
        debugPrint(
          '[MockAuth] ℹ️ No persisted session found (hashCode=$hashCode)',
        );
      }
    } catch (e) {
      debugPrint(
        '[MockAuth] ⚠️ Failed to restore session: $e (hashCode=$hashCode)',
      );
    }
    debugPrint('[TRACE] [MockAuth restoreSession End] hashCode=$hashCode');
  }

  // ── Persist session ───────────────────────────────────────────────────────
  Future<void> _persistSession(String? userId) async {
    debugPrint(
      '[TRACE] [MockAuth _persistSession] Persisting userId: $userId hashCode=$hashCode',
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setString(_kMockUserIdKey, userId);
        debugPrint('[MockAuth] 💾 Session persisted: $userId');
        if (userId.startsWith('staff-') && _currentStaff != null) {
          final staffJson = jsonEncode(_currentStaff!.toJson());
          await prefs.setString(_kMockStaffSessionKey, staffJson);
          debugPrint('[MockAuth] 💾 Staff session persisted: $staffJson');
        }
      } else {
        await prefs.remove(_kMockUserIdKey);
        await prefs.remove(_kMockStaffSessionKey);
        debugPrint('[MockAuth] 🗑️ Session cleared from storage');
      }
    } catch (e) {
      debugPrint(
        '[MockAuth] ⚠️ Failed to persist session: $e (hashCode=$hashCode)',
      );
    }
  }

  // ── Email + password sign-in ──────────────────────────────────────────────
  @override
  Future<LoginResponseDto> signInWithPassword(LoginRequestDto request) async {
    debugPrint(
      '[MockAuth] 🔐 Login attempt: ${request.email} hashCode=$hashCode',
    );
    debugPrint('[TRACE] [signInWithPassword Start] email=${request.email}');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (request.email.isEmpty || !request.email.contains('@')) {
      debugPrint('[MockAuth] ❌ Invalid email');
      return LoginResponseDto.failure('Invalid email address.');
    }
    if (request.password.length < 6) {
      debugPrint('[MockAuth] ❌ Password too short');
      return LoginResponseDto.failure(
        'Password must be at least 6 characters.',
      );
    }

    // Accept any valid-format credentials in mock mode
    _currentUserId = 'mock-user-admin-001';
    _currentStaff = null; // Clear staff if admin logging in
    _authStateController.add(_currentUserId);
    await _persistSession(_currentUserId);

    debugPrint(
      '[MockAuth] ✅ Login success → userId: $_currentUserId (hashCode=$hashCode)',
    );

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
    debugPrint(
      '[MockAuth] 🔐 Staff PIN login: ${request.tenantSlug} hashCode=$hashCode',
    );
    debugPrint(
      '[TRACE] [staffPinLogin Start] tenantSlug=${request.tenantSlug}',
    );
    await Future.delayed(const Duration(milliseconds: 600));

    final raw = await rootBundle.loadString(
      'lib/core/data/mock/fixtures/auth_fixtures.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final pins = (json['mock_credentials']['staff_pins'] as List)
        .cast<Map<String, dynamic>>();

    final match = pins
        .where(
          (p) =>
              p['pin'] == request.pin && p['tenant_slug'] == request.tenantSlug,
        )
        .firstOrNull;

    if (match == null) {
      debugPrint('[MockAuth] ❌ Invalid PIN');
      return StaffPinLoginResponseDto.failure(
        'Invalid PIN or restaurant code.',
      );
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
    _currentStaff = staffDto;
    _authStateController.add(_currentUserId);
    await _persistSession(_currentUserId);

    debugPrint(
      '[MockAuth] ✅ Staff login success → ${staffDto.name} (${staffDto.role}) (hashCode=$hashCode)',
    );
    return StaffPinLoginResponseDto(isSuccess: true, staff: staffDto);
  }

  // ── Resolve app context ───────────────────────────────────────────────────
  @override
  Future<AppContextDto?> resolveContext() async {
    debugPrint('[MockAuth] 🔍 Resolving context... hashCode=$hashCode');
    await Future.delayed(const Duration(milliseconds: 200));

    final raw = await rootBundle.loadString(
      'lib/core/data/mock/fixtures/auth_fixtures.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final ctx = AppContextDto.fromJson(json['context'] as Map<String, dynamic>);
    debugPrint(
      '[MockAuth] ✅ Context resolved: tenant=${ctx.tenant.name} hashCode=$hashCode',
    );
    return ctx;
  }

  // ── Change password ───────────────────────────────────────────────────────
  @override
  Future<void> changePassword(String email, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint(
      '[MockAuth] 🔑 Password changed (mock no-op) hashCode=$hashCode',
    );
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  @override
  Future<void> signOut() async {
    debugPrint('[MockAuth] 🚪 Signing out... hashCode=$hashCode');
    debugPrint('[TRACE] [signOut Start]');
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUserId = null;
    _currentStaff = null;
    _authStateController.add(null);
    await _persistSession(null);
    debugPrint('[MockAuth] ✅ Signed out hashCode=$hashCode');
  }
}
