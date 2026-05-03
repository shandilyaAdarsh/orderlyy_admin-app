/// Models for the payload returned by the `resolve-context-v2` edge function.
/// Never store these in SharedPreferences — hold in Riverpod state only.
library;

class UserContext {
  final String id;
  final String fullName;
  final String role;
  final bool mustChangePassword;

  const UserContext({
    required this.id,
    required this.fullName,
    required this.role,
    required this.mustChangePassword,
  });

  factory UserContext.fromJson(Map<String, dynamic> json) => UserContext(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        role: json['role'] as String,
        mustChangePassword: json['must_change_password'] as bool? ?? false,
      );
}

class TenantContext {
  final String id;
  final String name;
  final String slug;
  final String plan;
  final String status;
  final bool isActive;
  final String? nextBillingDate;

  const TenantContext({
    required this.id,
    required this.name,
    required this.slug,
    required this.plan,
    required this.status,
    required this.isActive,
    this.nextBillingDate,
  });

  factory TenantContext.fromJson(Map<String, dynamic> json) => TenantContext(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        plan: json['plan'] as String,
        status: json['status'] as String,
        isActive: json['is_active'] as bool? ?? true,
        nextBillingDate: json['next_billing_date'] as String?,
      );
}

class OnboardingContext {
  final bool isComplete;
  final List<String> stepsCompleted;

  const OnboardingContext({
    required this.isComplete,
    required this.stepsCompleted,
  });

  factory OnboardingContext.fromJson(Map<String, dynamic> json) =>
      OnboardingContext(
        isComplete: json['is_complete'] as bool? ?? false,
        stepsCompleted:
            List<String>.from(json['steps_completed'] as List? ?? []),
      );
}

class ContextFlags {
  final bool mustChangePassword;
  final bool subscriptionExpired;
  final bool accountSuspended;
  final bool onboardingRequired;

  const ContextFlags({
    required this.mustChangePassword,
    required this.subscriptionExpired,
    required this.accountSuspended,
    required this.onboardingRequired,
  });

  factory ContextFlags.fromJson(Map<String, dynamic> json) => ContextFlags(
        mustChangePassword: json['must_change_password'] as bool? ?? false,
        subscriptionExpired: json['subscription_expired'] as bool? ?? false,
        accountSuspended: json['account_suspended'] as bool? ?? false,
        onboardingRequired: json['onboarding_required'] as bool? ?? false,
      );
}

/// Root context object. Populated after every successful `resolve-context-v2` call.
class AppContext {
  final UserContext user;
  final TenantContext tenant;
  final OnboardingContext onboarding;
  final ContextFlags flags;

  const AppContext({
    required this.user,
    required this.tenant,
    required this.onboarding,
    required this.flags,
  });

  factory AppContext.fromJson(Map<String, dynamic> json) => AppContext(
        user: UserContext.fromJson(json['user'] as Map<String, dynamic>),
        tenant: TenantContext.fromJson(json['tenant'] as Map<String, dynamic>),
        onboarding: OnboardingContext.fromJson(
            json['onboarding'] as Map<String, dynamic>),
        flags: ContextFlags.fromJson(json['flags'] as Map<String, dynamic>),
      );
}
