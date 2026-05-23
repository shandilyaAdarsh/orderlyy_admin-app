// ── Staff Domain DTOs ─────────────────────────────────────────────────────────
// API-compatible. All enums are string-backed to match future JSON payloads.

library;

// ── Staff role enum ───────────────────────────────────────────────────────────

enum StaffRole {
  owner,
  manager,
  waiter;

  static StaffRole fromString(String value) => StaffRole.values.firstWhere(
    (e) => e.name == value,
    orElse: () => StaffRole.waiter,
  );

  String get displayLabel => switch (this) {
    StaffRole.owner => 'OWNER',
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

  const StaffDto({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.role,
    required this.pin,
    required this.isActive,
  });

  factory StaffDto.fromJson(Map<String, dynamic> json) => StaffDto(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    name: json['name'] as String? ?? 'Unknown',
    role: StaffRole.fromString(json['role'] as String? ?? 'waiter'),
    pin: json['pin'] as String? ?? '----',
    isActive: json['is_active'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'name': name,
    'role': role.name,
    'pin': pin,
    'is_active': isActive,
  };

  StaffDto copyWith({
    String? name,
    StaffRole? role,
    String? pin,
    bool? isActive,
  }) => StaffDto(
    id: id,
    tenantId: tenantId,
    name: name ?? this.name,
    role: role ?? this.role,
    pin: pin ?? this.pin,
    isActive: isActive ?? this.isActive,
  );
}
