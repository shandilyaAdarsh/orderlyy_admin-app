import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

// ── Auth service provider ──────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ── Current user provider ──────────────────────────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// ── Auth state stream provider ─────────────────────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// ── User profile provider ──────────────────────────────────────────────────────
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.read(authServiceProvider);
  return await authService.getUserProfile();
});

// ── Staff session model ────────────────────────────────────────────────────────
class StaffSession {
  final String id;
  final String name;
  final String role;
  final String tenantId;
  final String tenantName;
  final String tenantSlug;

  StaffSession({
    required this.id,
    required this.name,
    required this.role,
    required this.tenantId,
    required this.tenantName,
    required this.tenantSlug,
  });

  factory StaffSession.fromMap(Map<String, dynamic> map) {
    final tenant = map['tenants'] as Map<String, dynamic>;
    return StaffSession(
      id: map['id'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      tenantId: map['tenant_id'] as String,
      tenantName: tenant['name'] as String,
      tenantSlug: tenant['slug'] as String,
    );
  }
}

// ── Staff session notifier ─────────────────────────────────────────────────────
class StaffSessionNotifier extends StateNotifier<StaffSession?> {
  StaffSessionNotifier() : super(null);

  void setStaff(Map<String, dynamic> data) {
    state = StaffSession.fromMap(data);
  }

  void clear() => state = null;
}

final staffSessionProvider =
    StateNotifierProvider<StaffSessionNotifier, StaffSession?>((ref) {
      return StaffSessionNotifier();
    });
