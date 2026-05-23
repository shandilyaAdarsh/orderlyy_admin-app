import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../dtos/auth_dto.dart';

const _kSupabaseStaffUserIdKey = 'supabase_auth_user_id';
const _kSupabaseStaffSessionKey = 'supabase_auth_staff_session';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  String? _currentUserId;
  StaffDto? _currentStaff;
  final _authStateController = StreamController<String?>.broadcast();
  late final StreamSubscription<AuthState> _authSubscription;

  SupabaseAuthRepository(this._client) {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      debugPrint('[SupabaseAuth] Auth state change event: $event');

      // If we are logged in as staff, ignore GoTrue auth events
      if (_currentUserId != null && _currentUserId!.startsWith('staff-')) {
        return;
      }

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        _currentUserId = session?.user.id;
        _currentStaff = null;
        _authStateController.add(_currentUserId);
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUserId = null;
        _currentStaff = null;
        _authStateController.add(null);
      }
    });
  }

  void dispose() {
    _authSubscription.cancel();
    _authStateController.close();
  }

  @override
  Stream<String?> get authStateStream => _authStateController.stream;

  @override
  String? get currentUserId => _currentUserId ?? _client.auth.currentUser?.id;

  @override
  StaffDto? get currentStaff => _currentStaff;

  @override
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString(_kSupabaseStaffUserIdKey);
      final savedStaffJson = prefs.getString(_kSupabaseStaffSessionKey);

      if (savedUserId != null && savedUserId.startsWith('staff-') && savedStaffJson != null) {
        _currentUserId = savedUserId;
        _currentStaff = StaffDto.fromJson(jsonDecode(savedStaffJson) as Map<String, dynamic>);
        _authStateController.add(_currentUserId);
        debugPrint('[SupabaseAuth] Restored staff session: $_currentUserId');
        return;
      }
    } catch (e) {
      debugPrint('[SupabaseAuth] Error restoring staff session: $e');
    }

    // Fallback to GoTrue session
    final session = _client.auth.currentSession;
    if (session != null) {
      _currentUserId = session.user.id;
      _currentStaff = null;
      _authStateController.add(_currentUserId);
      debugPrint('[SupabaseAuth] Restored admin session: $_currentUserId');
    } else {
      _currentUserId = null;
      _currentStaff = null;
      _authStateController.add(null);
      debugPrint('[SupabaseAuth] No active session restored.');
    }
  }

  @override
  Future<LoginResponseDto> signInWithPassword(LoginRequestDto request) async {
    try {
      // Clear staff session first
      await _clearStaffSession();

      final response = await _client.auth.signInWithPassword(
        email: request.email,
        password: request.password,
      );

      final user = response.user;
      if (user == null) {
        return LoginResponseDto.failure('Authentication failed: user is null');
      }

      _currentUserId = user.id;
      _currentStaff = null;
      _authStateController.add(_currentUserId);

      return LoginResponseDto(
        userId: user.id,
        email: user.email ?? request.email,
        accessToken: response.session?.accessToken,
        isSuccess: true,
      );
    } on AuthException catch (e) {
      return LoginResponseDto.failure(e.message);
    } catch (e) {
      return LoginResponseDto.failure(e.toString());
    }
  }

  @override
  Future<StaffPinLoginResponseDto> staffPinLogin(
    StaffPinLoginRequestDto request,
  ) async {
    try {
      // 1. Clear any active session first
      try {
        await _client.auth.signOut();
      } catch (_) {}
      await _clearStaffSession();

      // 2. Query staff table joined on tenants
      final response = await _client
          .from('staff')
          .select('*, tenants!inner(*)')
          .eq('tenants.slug', request.tenantSlug)
          .eq('pin', request.pin)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        return StaffPinLoginResponseDto.failure('Invalid PIN or restaurant code.');
      }

      final staff = StaffDto.fromJson(response);

      _currentUserId = staff.id;
      _currentStaff = staff;

      // Persist staff session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSupabaseStaffUserIdKey, staff.id);
      await prefs.setString(_kSupabaseStaffSessionKey, jsonEncode(staff.toJson()));

      _authStateController.add(_currentUserId);

      return StaffPinLoginResponseDto(
        isSuccess: true,
        staff: staff,
      );
    } catch (e) {
      return StaffPinLoginResponseDto.failure(e.toString());
    }
  }

  @override
  Future<AppContextDto?> resolveContext() async {
    // If logged in as staff, we don't have a GoTrue session to call the edge function with
    if (_currentUserId != null && _currentUserId!.startsWith('staff-')) {
      final staff = _currentStaff;
      if (staff != null) {
        return AppContextDto(
          user: UserContextDto(
            id: staff.id,
            fullName: staff.name,
            role: staff.role,
            mustChangePassword: false,
          ),
          tenant: TenantContextDto(
            id: staff.tenantId,
            name: staff.tenantName,
            slug: staff.tenantSlug,
            plan: 'standard',
            status: 'active',
            isActive: true,
          ),
          onboarding: const OnboardingContextDto(
            isComplete: true,
            stepsCompleted: [],
          ),
          flags: const ContextFlagsDto(
            mustChangePassword: false,
            subscriptionExpired: false,
            accountSuspended: false,
            onboardingRequired: false,
          ),
        );
      }
      return null;
    }

    final res = await _client.functions.invoke('resolve-context-v2');

    if (res.status == 401) {
      await signOut();
      return null;
    }

    if (res.status >= 400) {
      final errorData = res.data;
      if (errorData is Map<String, dynamic>) {
        final message = (errorData['message'] ?? errorData['error'])?.toString();
        throw Exception(message ?? 'Unable to resolve account context.');
      }
      throw Exception('Unable to resolve account context.');
    }

    if (res.data == null || res.data is! Map<String, dynamic>) {
      return null;
    }

    return AppContextDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword(String email, String newPassword) async {
    final res = await _client.functions.invoke(
      'change-password',
      body: {'new_password': newPassword},
    );

    if (res.data is Map && res.data['error'] != null) {
      throw Exception(res.data['error']);
    }

    // Re-authenticate with new password
    final loginRes = await _client.auth.signInWithPassword(
      email: email,
      password: newPassword,
    );
    if (loginRes.session == null) {
      throw Exception('Re-login failed after password change');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
    await _clearStaffSession();
    _authStateController.add(null);
  }

  Future<void> _clearStaffSession() async {
    _currentUserId = null;
    _currentStaff = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSupabaseStaffUserIdKey);
      await prefs.remove(_kSupabaseStaffSessionKey);
    } catch (_) {}
  }
}
