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
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/repository_providers.dart';
import '../data/dtos/auth_dto.dart';
import '../network/api_exception.dart';
import 'bootstrap_provider.dart';
import 'bootstrap_state.dart';
import '../runtime/runtime_reset_service.dart';

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
      debugPrint(
        '[TRACE] [AuthNotifier _init] Session restored for userId=$restoredUserId — triggering bootstrap',
      );
      // Set auth state FIRST, then trigger bootstrap (strictly separated)
      state = AuthState.authenticated(restoredUserId);
      // Bootstrap runs independently — does not block auth state
      unawaited(
        _ref.read(bootstrapProvider.notifier).resolve(restoredUserId),
      );
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
        // Authenticated — set auth state, then trigger bootstrap separately
        state = AuthState.authenticated(newUserId);
        unawaited(
          _ref.read(bootstrapProvider.notifier).resolve(newUserId),
        );
      } else {
        // Logout — clear local repositories and projections BEFORE clearing auth state
        await RuntimeResetService.fullReset();
        _ref.read(bootstrapProvider.notifier).reset();
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
    // Watch authNotifierProvider — rebuild (and notify) on every auth change
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      debugPrint(
        '[RouterNotifier] 🔔 Auth changed: ${previous?.status} → ${next.status}',
      );
      notifyListeners();
    });
    // Also watch bootstrapProvider — router must re-evaluate on every bootstrap transition
    _ref.listen<BootstrapState>(bootstrapProvider, (previous, next) {
      debugPrint(
        '[RouterNotifier] 🔔 Bootstrap changed: ${previous?.status} → ${next.status}',
      );
      notifyListeners();
    });
    _ref.listen<AppContextDto?>(appContextProvider, (previous, next) {
      if (previous?.onboarding.step != next?.onboarding.step ||
          previous?.onboarding.stepsCompleted.length !=
              next?.onboarding.stepsCompleted.length ||
          previous?.flags.onboardingRequired != next?.flags.onboardingRequired) {
        debugPrint('[RouterNotifier] 🔔 App context onboarding changed');
        notifyListeners();
      }
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

class AppContextNotifier extends StateNotifier<AppContextDto?> {
  final Ref _ref;

  AppContextNotifier(this._ref) : super(null);

  String? get currentUserEmail => null;

  /// Directly set the resolved context (called by BootstrapNotifier).
  void setContext(AppContextDto ctx) {
    debugPrint('[AppContext] ✅ Context set from bootstrap: ${ctx.tenant.name}');
    state = ctx;
  }

  /// Call this after a successful sign-in to populate tenant context.
  /// Kept for backward compatibility — prefer using BootstrapNotifier.resolve().
  Future<AppContextDto?> resolveContext() async {
    debugPrint('[AppContext] 🔍 Resolving context...');
    final repo = _ref.read(authRepositoryProvider);
    final result = await repo.resolveContext();

    AppContextDto? ctx;
    if (result is Success) {
      ctx = (result as Success<AppContextDto?>).value;
    } else {
      debugPrint(
        '[AppContext] ⚠️ Context resolution failed: ${(result as Failure).error.message}',
      );
    }

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

  /// Complete onboarding step and persist to database
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

    try {
      final client = Supabase.instance.client;
      await client.from('onboarding_state').upsert(
        {
          'tenant_id': tenantId,
          'steps_completed': currentSteps,
          'is_complete': isLastStep,
          'is_skipped': false,
        },
        onConflict: 'tenant_id',
      );
      debugPrint('[AppContext] 💾 Saved onboarding step $stepName to database.');
    } catch (e) {
      debugPrint('[AppContext] ❌ Failed to save onboarding step to database: $e');
    }

    // Update local state
    final newOnboarding = OnboardingContextDto(
      isComplete: isLastStep,
      isSkipped: false,
      step: isLastStep ? 4 : state!.onboarding.step + 1,
      stepsCompleted: currentSteps,
    );

    // If onboarding is complete, flags should also reflect that onboarding is no longer required
    final newFlags = ContextFlagsDto(
      mustChangePassword: state!.flags.mustChangePassword,
      isFirstLogin: state!.flags.isFirstLogin,
      subscriptionExpired: state!.flags.subscriptionExpired,
      accountSuspended: state!.flags.accountSuspended,
      onboardingRequired: !isLastStep,
    );

    state = AppContextDto(
      tenant: state!.tenant,
      user: state!.user,
      onboarding: newOnboarding,
      flags: newFlags,
    );

    debugPrint(
      '[AppContext] 📋 Onboarding state updated: ${currentSteps.length} steps completed',
    );
  }

  /// After a backend onboarding API saves a step, sync local step so routing updates
  /// without a full bootstrap reload (which is skipped when already onboardingRequired).
  void applyOnboardingProgress({
    required String completedStep,
    required int nextStep,
  }) {
    if (state == null) return;

    final steps = List<String>.from(state!.onboarding.stepsCompleted);
    if (!steps.contains(completedStep)) {
      steps.add(completedStep);
    }

    state = AppContextDto(
      tenant: state!.tenant,
      user: state!.user,
      flags: state!.flags,
      onboarding: OnboardingContextDto(
        isComplete: state!.onboarding.isComplete,
        isSkipped: state!.onboarding.isSkipped,
        step: nextStep,
        stepsCompleted: steps,
      ),
    );
    debugPrint(
      '[AppContext] 📋 Onboarding progress: $completedStep done → step $nextStep',
    );
  }

  /// Mark onboarding finished locally (e.g. after final step API succeeds).
  void markOnboardingFinished() {
    if (state == null) return;

    final steps = List<String>.from(state!.onboarding.stepsCompleted);
    for (final key in [
      'restaurant_info',
      'business_config',
      'gst_legal',
      'tables_hours',
    ]) {
      if (!steps.contains(key)) steps.add(key);
    }

    state = AppContextDto(
      tenant: state!.tenant,
      user: state!.user,
      onboarding: OnboardingContextDto(
        isComplete: true,
        isSkipped: false,
        step: 5,
        stepsCompleted: steps,
      ),
      flags: ContextFlagsDto(
        mustChangePassword: state!.flags.mustChangePassword,
        isFirstLogin: state!.flags.isFirstLogin,
        subscriptionExpired: state!.flags.subscriptionExpired,
        accountSuspended: state!.flags.accountSuspended,
        onboardingRequired: false,
      ),
    );
    debugPrint('[AppContext] ✅ Onboarding marked complete locally');
  }

  void clearContext() {
    debugPrint('[AppContext] 🗑️ Context cleared');
    state = null;
  }
}

final appContextProvider =
    StateNotifierProvider<AppContextNotifier, AppContextDto?>((ref) {
      return AppContextNotifier(ref);
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

/// Basic user class for UI elements needing user details
class AppUser {
  final String id;
  final String email;

  const AppUser({required this.id, required this.email});
}

/// Provides the current user object for UI compatibility
final currentUserProvider = Provider<AppUser?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final email = Supabase.instance.client.auth.currentUser?.email ?? '';

  return AppUser(id: userId, email: email);
});

/// Mock auth service for compatibility
class AppAuthService {
  final Ref _ref;

  AppAuthService(this._ref);

  Future<void> signOut() async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final repo = _ref.read(authRepositoryProvider);
    final result = await repo.resolveContext();

    AppContextDto? ctx;
    if (result is Success) {
      ctx = (result as Success<AppContextDto?>).value;
    }

    return ctx != null
        ? {
            'name': ctx.user.fullName,
            'email': Supabase.instance.client.auth.currentUser?.email ?? '',
            'tenants': {
              'name': ctx.tenant.name,
              'slug': ctx.tenant.slug,
              'address': '',
            },
          }
        : null;
  }
}

final authServiceProvider = Provider<AppAuthService>((ref) {
  return AppAuthService(ref);
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.read(authServiceProvider);
  return await authService.getUserProfile();
});

