import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  // ── Admin login with email + password ──────────────────────────────────────
  Future<AuthResponse> signInWithPassword(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Send phone OTP ─────────────────────────────────────────────────────────
  Future<void> sendOTP(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  // ── Verify phone OTP ───────────────────────────────────────────────────────
  Future<AuthResponse> verifyOTP(String phone, String token) async {
    return await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  // ── Get user profile from profiles table ───────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final profile = await _client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) return null;

      final tenantId = profile['tenant_id'];
      if (tenantId != null) {
        try {
          final tenant = await _client
              .from('tenants')
              .select('*')
              .eq('id', tenantId)
              .maybeSingle();

          if (tenant != null) {
            profile['tenants'] = tenant;
          }
        } catch (_) {
          // Ignore tenant lookup failures to avoid blocking profile rendering.
        }
      }

      return profile;
    } catch (_) {
      return null;
    }
  }

  // ── Staff PIN login ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> staffPinLogin(
    String tenantSlug,
    String pin,
  ) async {
    final response = await _client
        .from('staff')
        .select('*, tenants!inner(*)')
        .eq('tenants.slug', tenantSlug)
        .eq('pin', pin)
        .eq('is_active', true)
        .maybeSingle();

    return response;
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Current user ───────────────────────────────────────────────────────────
  User? get currentUser => _client.auth.currentUser;

  // ── Auth state stream ──────────────────────────────────────────────────────
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
