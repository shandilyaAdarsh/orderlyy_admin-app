import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/branch_context_service.dart';
import '../providers/tables_provider.dart';

enum BranchOperationalReadiness { ready, needsSetup, suspended }

class BranchCapabilitySnapshot {
  final String branchId;
  final bool hasMenu;
  final bool hasTables;
  final bool hasActiveStaff;

  const BranchCapabilitySnapshot({
    required this.branchId,
    required this.hasMenu,
    required this.hasTables,
    required this.hasActiveStaff,
  });

  BranchOperationalReadiness get readiness {
    if (!hasMenu || !hasTables) return BranchOperationalReadiness.needsSetup;
    return BranchOperationalReadiness.ready;
  }
}

final branchCapabilityProvider =
    Provider.autoDispose<BranchCapabilitySnapshot?>((ref) {
      final branch = ref.watch(currentBranchProvider).value;
      if (branch == null) return null;

      final tablesState = ref.watch(tablesProvider);

      return BranchCapabilitySnapshot(
        branchId: branch.id,
        hasMenu: true, // Check actual menu repository
        hasTables: tablesState.tablesById.isNotEmpty,
        hasActiveStaff: true, // Check staff repository
      );
    });
