import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_context_model.dart';

// ── AppContext Notifier ────────────────────────────────────────────────────────
// Holds resolved context in memory ONLY — never persisted to disk.
// Always call resolveContext() immediately after signInWithPassword succeeds.

class AppContextNotifier extends StateNotifier<AppContext?> {
  // Public getter for current user email
  String? get currentUserEmail => _client.auth.currentUser?.email;
  AppContextNotifier() : super(null);

  final _client = Supabase.instance.client;

  // ── Step 2 of login flow: call after signInWithPassword ────────────────────
  Future<AppContext?> resolveContext() async {
    final res = await _client.functions.invoke('resolve-context-v2');

    if (res.status == 401) {
      // Session expired or invalidated — go to login silently, no error shown
      await _client.auth.signOut();
      state = null;
      return null;
    }

    if (res.status >= 400) {
      final errorData = res.data;
      if (errorData is Map<String, dynamic>) {
        final message = (errorData['message'] ?? errorData['error'])
            ?.toString();
        throw Exception(message ?? 'Unable to resolve account context.');
      }
      throw Exception('Unable to resolve account context.');
    }

    if (res.data == null) {
      throw Exception('resolve-context-v2 returned null');
    }

    if (res.data is! Map<String, dynamic>) {
      throw Exception('resolve-context-v2 returned invalid payload');
    }

    final context = AppContext.fromJson(res.data as Map<String, dynamic>);
    state = context;
    return context;
  }

  // ── Change password, re-login, then re-resolve context ─────────────────────
  Future<void> changePassword(String email, String newPassword) async {
    final res = await _client.functions.invoke(
      'change-password',
      body: {'new_password': newPassword},
    );

    if (res.data is Map && res.data['error'] != null) {
      throw Exception(res.data['error']);
    }

    // Re-authenticate with new password (session is now invalid)
    final loginRes = await _client.auth.signInWithPassword(
      email: email,
      password: newPassword,
    );
    if (loginRes.session == null) {
      throw Exception('Re-login failed after password change');
    }

    // Now resolve context with fresh session
    await resolveContext();
  }

  // ── Clear on logout ─────────────────────────────────────────────────────────
  void clearContext() => state = null;
}

// ── Provider ──────────────────────────────────────────────────────────────────
final appContextProvider =
    StateNotifierProvider<AppContextNotifier, AppContext?>((ref) {
      return AppContextNotifier();
    });
