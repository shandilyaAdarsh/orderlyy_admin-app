// ── AuthRepository interface ───────────────────────────────────────────────────
// The UI layer ONLY depends on this contract — never on Supabase directly.
// Implementations: MockAuthRepository (dev) | SupabaseAuthRepository (prod)

import '../dtos/auth_dto.dart';

abstract class AuthRepository {
  // ── Email + password sign-in ─────────────────────────────────────────────
  Future<LoginResponseDto> signInWithPassword(LoginRequestDto request);

  // ── Staff PIN sign-in ────────────────────────────────────────────────────
  Future<StaffPinLoginResponseDto> staffPinLogin(
    StaffPinLoginRequestDto request,
  );

  // ── Resolve app/tenant context after login ───────────────────────────────
  Future<AppContextDto?> resolveContext();

  // ── Change password (requires active session) ────────────────────────────
  Future<void> changePassword(String email, String newPassword);

  // ── Sign out ─────────────────────────────────────────────────────────────
  Future<void> signOut();

  // ── Auth state stream (nullable = logged out) ────────────────────────────
  // Emits null when logged out, user-id string when logged in.
  Stream<String?> get authStateStream;

  // ── Currently authenticated user id ──────────────────────────────────────
  String? get currentUserId;
}
