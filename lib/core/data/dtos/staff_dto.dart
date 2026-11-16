// ── Staff Domain DTOs ─────────────────────────────────────────────────────────
// API-compatible. All enums are string-backed to match future JSON payloads.

library;

// ── Staff role enum ───────────────────────────────────────────────────────────

enum StaffRole {
  kitchen,
  manager,
  waiter;

  static StaffRole fromString(String value) => StaffRole.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => StaffRole.waiter,
  );

  String get displayLabel => switch (this) {
    StaffRole.kitchen => 'COOK',
    StaffRole.manager => 'MANAGER',
    StaffRole.waiter => 'WAITER',
  };
}

// ── Staff member ──────────────────────────────────────────────────────────────

class StaffDto {
  final String id;
  final String tenantId;
  final String name;
  final StaffRole role;
  final String pin;
  final bool isActive;
  final String? employeeId;
  final String? branchId;
  final String? email;

  const StaffDto({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.role,
    required this.pin,
    required this.isActive,
    this.employeeId,
    this.branchId,
    this.email,
  });

  factory StaffDto.fromJson(Map<String, dynamic> json) => StaffDto(
    id: json['id']?.toString() ?? '',
    tenantId: json['tenant_id']?.toString() ?? '',
    name: (json['name'] ?? json['full_name'])?.toString() ?? 'Unknown',
    role: StaffRole.fromString(json['role']?.toString() ?? 'waiter'),
    pin: json['pin']?.toString() ?? '----',
    isActive: json['is_active'] as bool? ?? true,
    employeeId: json['employee_id']?.toString(),
    branchId: json['branch_id']?.toString(),
    email: json['email']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'name': name,
    'role': role.name,
    'pin': pin,
    'is_active': isActive,
    'employee_id': employeeId,
    'branch_id': branchId,
    'email': email,
  };

  StaffDto copyWith({
    String? id,
    String? tenantId,
    String? name,
    StaffRole? role,
    String? pin,
    bool? isActive,
    String? employeeId,
    String? branchId,
    String? email,
  }) => StaffDto(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    name: name ?? this.name,
    role: role ?? this.role,
    pin: pin ?? this.pin,
    isActive: isActive ?? this.isActive,
    employeeId: employeeId ?? this.employeeId,
    branchId: branchId ?? this.branchId,
    email: email ?? this.email,
  );
}
