// lib/features/auth/domain/entities/staff_member.dart

enum StaffRole { waiter, runner, host, kdsOperator, manager }

class StaffMember {
  final String id;
  final String name;
  final String pin;
  final StaffRole role;
  final String? section;

  const StaffMember({
    required this.id,
    required this.name,
    required this.pin,
    required this.role,
    this.section,
  });

  StaffMember copyWith({
    String? id,
    String? name,
    String? pin,
    StaffRole? role,
    String? section,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      section: section ?? this.section,
    );
  }
}
