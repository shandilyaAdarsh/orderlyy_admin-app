// ── Auth Domain DTOs ──────────────────────────────────────────────────────────
// These mirror the contracts from resolve-context-v2 and auth endpoints.
// Keep field names snake_case to match future API payloads.
// Never store sensitive fields (tokens, passwords) in these objects.

library;

// ── Login request / response ──────────────────────────────────────────────────

class LoginRequestDto {
  final String email;
  final String password;

  const LoginRequestDto({required this.email, required this.password});
}

class LoginResponseDto {
  final String userId;
  final String email;
  final String? accessToken;  // nullable — mocks won't issue real tokens
  final bool isSuccess;
  final String? errorMessage;

  const LoginResponseDto({
    required this.userId,
    required this.email,
    this.accessToken,
    required this.isSuccess,
    this.errorMessage,
  });

  factory LoginResponseDto.failure(String message) => LoginResponseDto(
        userId: '',
        email: '',
        isSuccess: false,
        errorMessage: message,
      );
}

// ── Staff PIN login ───────────────────────────────────────────────────────────

class StaffPinLoginRequestDto {
  final String tenantSlug;
  final String pin;

  const StaffPinLoginRequestDto({
    required this.tenantSlug,
    required this.pin,
  });
}

class StaffPinLoginResponseDto {
  final bool isSuccess;
  final StaffDto? staff;
  final String? errorMessage;

  const StaffPinLoginResponseDto({
    required this.isSuccess,
    this.staff,
    this.errorMessage,
  });

  factory StaffPinLoginResponseDto.failure(String message) =>
      StaffPinLoginResponseDto(isSuccess: false, errorMessage: message);
}

// ── Staff DTO ─────────────────────────────────────────────────────────────────

class StaffDto {
  final String id;
  final String name;
  final String role;
  final String tenantId;
  final String tenantName;
  final String tenantSlug;
  final bool isActive;

  const StaffDto({
    required this.id,
    required this.name,
    required this.role,
    required this.tenantId,
    required this.tenantName,
    required this.tenantSlug,
    required this.isActive,
  });

  factory StaffDto.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenants'] as Map<String, dynamic>? ?? {};
    return StaffDto(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      tenantId: json['tenant_id'] as String,
      tenantName: tenant['name'] as String? ?? '',
      tenantSlug: tenant['slug'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'tenant_id': tenantId,
        'tenants': {'name': tenantName, 'slug': tenantSlug},
        'is_active': isActive,
      };
}

// ── App context DTO (from resolve-context-v2) ─────────────────────────────────

class AppContextDto {
  final UserContextDto user;
  final TenantContextDto tenant;
  final OnboardingContextDto onboarding;
  final ContextFlagsDto flags;

  const AppContextDto({
    required this.user,
    required this.tenant,
    required this.onboarding,
    required this.flags,
  });

  factory AppContextDto.fromJson(Map<String, dynamic> json) => AppContextDto(
        user: UserContextDto.fromJson(json['user'] as Map<String, dynamic>),
        tenant:
            TenantContextDto.fromJson(json['tenant'] as Map<String, dynamic>),
        onboarding: OnboardingContextDto.fromJson(
            json['onboarding'] as Map<String, dynamic>),
        flags:
            ContextFlagsDto.fromJson(json['flags'] as Map<String, dynamic>),
      );
}

class UserContextDto {
  final String id;
  final String fullName;
  final String role;
  final bool mustChangePassword;

  const UserContextDto({
    required this.id,
    required this.fullName,
    required this.role,
    required this.mustChangePassword,
  });

  factory UserContextDto.fromJson(Map<String, dynamic> json) => UserContextDto(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        role: json['role'] as String,
        mustChangePassword: json['must_change_password'] as bool? ?? false,
      );
}

class TenantContextDto {
  final String id;
  final String name;
  final String slug;
  final String plan;
  final String status;
  final bool isActive;
  final String? nextBillingDate;

  const TenantContextDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.plan,
    required this.status,
    required this.isActive,
    this.nextBillingDate,
  });

  factory TenantContextDto.fromJson(Map<String, dynamic> json) =>
      TenantContextDto(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        plan: json['plan'] as String,
        status: json['status'] as String,
        isActive: json['is_active'] as bool? ?? true,
        nextBillingDate: json['next_billing_date'] as String?,
      );
}

class OnboardingContextDto {
  final bool isComplete;
  final List<String> stepsCompleted;

  const OnboardingContextDto({
    required this.isComplete,
    required this.stepsCompleted,
  });

  factory OnboardingContextDto.fromJson(Map<String, dynamic> json) =>
      OnboardingContextDto(
        isComplete: json['is_complete'] as bool? ?? false,
        stepsCompleted:
            List<String>.from(json['steps_completed'] as List? ?? []),
      );
}

class ContextFlagsDto {
  final bool mustChangePassword;
  final bool subscriptionExpired;
  final bool accountSuspended;
  final bool onboardingRequired;

  const ContextFlagsDto({
    required this.mustChangePassword,
    required this.subscriptionExpired,
    required this.accountSuspended,
    required this.onboardingRequired,
  });

  factory ContextFlagsDto.fromJson(Map<String, dynamic> json) =>
      ContextFlagsDto(
        mustChangePassword: json['must_change_password'] as bool? ?? false,
        subscriptionExpired: json['subscription_expired'] as bool? ?? false,
        accountSuspended: json['account_suspended'] as bool? ?? false,
        onboardingRequired: json['onboarding_required'] as bool? ?? false,
      );
}
