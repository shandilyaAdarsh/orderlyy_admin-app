// ── Mock Auth Provider ────────────────────────────────────────────────────────
// Replaces the Supabase-coupled auth_provider.dart + app_context_provider.dart
// during the mock phase.
//
// All Supabase imports removed. Everything goes through AuthRepository.
// The UI still reads from the same provider names to minimise churn.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_providers.dart';
import '../data/dtos/auth_dto.dart';

// ── App context notifier ──────────────────────────────────────────────────────

class MockAppContextNotifier extends StateNotifier<AppContextDto?> {
  final Ref _ref;

  MockAppContextNotifier(this._ref) : super(null);

  String? get currentUserEmail => null; // No email in mock session model

  /// Call this after a successful sign-in to populate tenant context.
  Future<AppContextDto?> resolveContext() async {
    final repo = _ref.read(authRepositoryProvider);
    final ctx = await repo.resolveContext();
    state = ctx;
    return ctx;
  }

  /// Change password — delegates to repository (no-op in mock).
  Future<void> changePassword(String email, String newPassword) async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.changePassword(email, newPassword);
    // Re-resolve context to refresh state
    await resolveContext();
  }

  void clearContext() => state = null;
}

final appContextProvider =
    StateNotifierProvider<MockAppContextNotifier, AppContextDto?>((ref) {
  return MockAppContextNotifier(ref);
});

// ── Staff session ─────────────────────────────────────────────────────────────

class MockStaffSession {
  final String id;
  final String name;
  final String role;
  final String tenantId;
  final String tenantName;
  final String tenantSlug;

  const MockStaffSession({
    required this.id,
    required this.name,
    required this.role,
    required this.tenantId,
    required this.tenantName,
    required this.tenantSlug,
  });

  factory MockStaffSession.fromDto(StaffDto dto) => MockStaffSession(
        id: dto.id,
        name: dto.name,
        role: dto.role,
        tenantId: dto.tenantId,
        tenantName: dto.tenantName,
        tenantSlug: dto.tenantSlug,
      );
}

class MockStaffSessionNotifier extends StateNotifier<MockStaffSession?> {
  MockStaffSessionNotifier() : super(null);

  void setStaff(StaffDto dto) => state = MockStaffSession.fromDto(dto);

  void clear() => state = null;
}

final staffSessionProvider =
    StateNotifierProvider<MockStaffSessionNotifier, MockStaffSession?>((ref) {
  return MockStaffSessionNotifier();
});

// ── Current user id stream (mock auth state) ──────────────────────────────────

final authStateStreamProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateStream;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.currentUserId;
});
