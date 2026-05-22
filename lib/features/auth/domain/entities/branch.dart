// lib/features/auth/domain/entities/branch.dart

enum BranchStatus { open, busy, outage }

class Branch {
  final String id;
  final String name;
  final BranchStatus status;
  final String syncPercentage;
  final int activeStaff;

  const Branch({
    required this.id,
    required this.name,
    required this.status,
    required this.syncPercentage,
    required this.activeStaff,
  });
}
