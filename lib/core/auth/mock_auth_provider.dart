// ── Mock Auth Provider ────────────────────────────────────────────────────────
// Replaces the Supabase-coupled auth_provider.dart + app_context_provider.dart
// during the mock phase.
//
// KEY DESIGN:
//   • authNotifierProvider  — StateNotifier<AuthState> driven by the auth stream.
//                             This is the single source of truth for "is logged in".
//   • currentUserIdProvider — derives from authNotifierProvider (reactive).
//   • routerNotifier        — ChangeNotifier that GoRouter listens to via
//                             refreshListenable; notifies on every auth change.
//   • appContextProvider    — holds resolved AppContextDto after login.
//
// PRODUCTION MIGRATION:
//   Replace MockAuthRepository with SupabaseAuthRepository in
//   repository_providers.dart. The provider structure here stays identical.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_providers.dart';
import '../data/dtos/auth_dto.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 0. Auth Status & State Definitions
// ─────────────────────────────────────────────────────────────────────────────

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? userId;

  const AuthState({required this.status, this.userId});

  const AuthState.loading() : status = AuthStatus.loading, userId = null;
  const AuthState.authenticated(String this.userId)
    : status = AuthStatus.authenticated;
  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      userId = null;

  @override
  String toString() => 'AuthState(status: $status, userId: $userId)';
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Auth Notifier — reactive StateNotifier<AuthState> driven by auth stream
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState.loading()) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<String?>? _sub;

  Future<void> _init() async {
    debugPrint('[TRACE] [AuthNotifier _init Start] Initializing auth state...');
    final repo = _ref.read(authRepositoryProvider);
    debugPrint('[AUTH INSTANCE] [AuthNotifier] repo.hashCode=${repo.hashCode}');

    // Restore persisted session first (works for mock & live repos)
    await repo.restoreSession();

    // Enforce a 2000ms minimum splash delay to display animations beautifully
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final restoredUserId = repo.currentUserId;
    if (restoredUserId != null) {
      try {
        debugPrint(
          '[TRACE] [AuthNotifier _init] Resolving context for admin: $restoredUserId',
        );
        await _ref.read(appContextProvider.notifier).resolveContext();
        state = AuthState.authenticated(restoredUserId);
      } catch (e) {
        debugPrint(
          '[MockAuth] ⚠️ Context resolution failed during initialization: $e',
        );
        state = AuthState.unauthenticated();
      }
    } else {
      state = AuthState.unauthenticated();
    }

    debugPrint(
      '[TRACE] [AuthNotifier _init Complete] Auth state initialized: $state',
    );

    // Subscribe to future stream changes
    _sub = repo.authStateStream.listen((newUserId) async {
      debugPrint(
        '[TRACE] [AuthNotifier Stream Listen] Received newUserId=$newUserId',
      );
      if (newUserId != null) {
        try {
          await _ref.read(appContextProvider.notifier).resolveContext();
          state = AuthState.authenticated(newUserId);
        } catch (e) {
          debugPrint(
            '[MockAuth] ⚠️ Context resolution failed on stream change: $e',
          );
          state = AuthState.unauthenticated();
        }
      } else {
        // Clear contexts upon logout
        _ref.read(appContextProvider.notifier).clearContext();
        state = AuthState.unauthenticated();
      }
      debugPrint(
        '[TRACE] [AuthNotifier Stream Processed] Auth state updated: $state',
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// 2. currentUserIdProvider — derives from authNotifierProvider (reactive)
// ─────────────────────────────────────────────────────────────────────────────

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).userId;
});

// ─────────────────────────────────────────────────────────────────────────────
// 3. RouterNotifier — ChangeNotifier that GoRouter uses as refreshListenable
//    Notifies GoRouter whenever auth state changes so redirect re-evaluates.
// ─────────────────────────────────────────────────────────────────────────────

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    // Watch authNotifierProvider — rebuild (and notify) on every change
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      debugPrint(
        '[RouterNotifier] 🔔 Notifying router: ${previous?.status} → ${next.status}',
      );
      notifyListeners();
    });
  }

  final Ref _ref;
}

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// 4. App context notifier — holds resolved AppContextDto after login
// ─────────────────────────────────────────────────────────────────────────────

class MockAppContextNotifier extends StateNotifier<AppContextDto?> {
  final Ref _ref;

  MockAppContextNotifier(this._ref) : super(null);

  String? get currentUserEmail => null;

  /// Call this after a successful sign-in to populate tenant context.
  Future<AppContextDto?> resolveContext() async {
    debugPrint('[AppContext] 🔍 Resolving context...');
    final repo = _ref.read(authRepositoryProvider);
    final ctx = await repo.resolveContext();
    state = ctx;
    debugPrint('[AppContext] ✅ Context set: ${ctx?.tenant.name}');
    return ctx;
  }

  /// Change password — delegates to repository (no-op in mock).
  Future<void> changePassword(String email, String newPassword) async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.changePassword(email, newPassword);
    await resolveContext();
  }

  /// Complete onboarding step (mock implementation)
  Future<void> completeOnboardingStep(
    String tenantId,
    String stepName,
    bool isLastStep,
  ) async {
    if (state == null) {
      debugPrint('[AppContext] ⚠️ No active context for onboarding step');
      return;
    }

    debugPrint(
      '[AppContext] ✅ Onboarding step completed: $stepName (isLast: $isLastStep)',
    );

    final currentSteps = List<String>.from(state!.onboarding.stepsCompleted);
    if (!currentSteps.contains(stepName)) {
      currentSteps.add(stepName);
    }

    // Update local state
    final newOnboarding = OnboardingContextDto(
      stepsCompleted: currentSteps,
      isComplete: isLastStep,
    );

    state = AppContextDto(
      tenant: state!.tenant,
      user: state!.user,
      onboarding: newOnboarding,
      flags: state!.flags,
    );

    debugPrint(
      '[AppContext] 📋 Onboarding state updated: ${currentSteps.length} steps completed',
    );
  }

  void clearContext() {
    debugPrint('[AppContext] 🗑️ Context cleared');
    state = null;
  }
}

final appContextProvider =
    StateNotifierProvider<MockAppContextNotifier, AppContextDto?>((ref) {
      return MockAppContextNotifier(ref);
    });

// ─────────────────────────────────────────────────────────────────────────────
// 5. Auth state stream provider (kept for compatibility)
// ─────────────────────────────────────────────────────────────────────────────

final authStateStreamProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateStream;
});

// ─────────────────────────────────────────────────────────────────────────────
// 6. Compatibility providers for screens that expect Supabase User type
// ─────────────────────────────────────────────────────────────────────────────

/// Mock user class to replace Supabase User
class MockUser {
  final String id;
  final String email;

  const MockUser({required this.id, required this.email});
}

/// Provides a mock user object for compatibility with screens expecting Supabase User
final currentUserProvider = Provider<MockUser?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  // For mock mode, derive email from userId
  final email = 'admin@orderlli.com';

  return MockUser(id: userId, email: email);
});

/// Mock auth service for compatibility
class MockAuthService {
  final Ref _ref;

  MockAuthService(this._ref);

  Future<void> signOut() async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final repo = _ref.read(authRepositoryProvider);
    return await repo.resolveContext().then(
      (ctx) => ctx != null
          ? {
              'name': 'Admin User',
              'email': 'admin@orderlli.com',
              'tenants': {
                'name': ctx.tenant.name,
                'slug': ctx.tenant.slug,
                'address': 'Mock Address',
              },
            }
          : null,
    );
  }
}

final authServiceProvider = Provider<MockAuthService>((ref) {
  return MockAuthService(ref);
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.read(authServiceProvider);
  return await authService.getUserProfile();
});
