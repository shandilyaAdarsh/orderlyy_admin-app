// lib/features/menu/runtime/merge_policy_registry.dart

enum MergePolicy { lastWriteWins, manualReviewRequired, tombstoneWins }

class ConflictEnvelope {
  final int baseRevision;
  final int localRevision;
  final int remoteRevision;
  final MergePolicy mergePolicy;
  final List<String> conflictFields;
  final String sourceDeviceId;
  final String sourceSessionId;

  const ConflictEnvelope({
    required this.baseRevision,
    required this.localRevision,
    required this.remoteRevision,
    required this.mergePolicy,
    required this.conflictFields,
    required this.sourceDeviceId,
    required this.sourceSessionId,
  });
}

class MergePolicyRegistry {
  /// Defines explicit field-level merge governance.
  static MergePolicy getPolicyForField(String fieldName) {
    switch (fieldName) {
      case 'price':
      case 'taxConfig':
      case 'modifierGroupIds':
        return MergePolicy.manualReviewRequired; // High-risk fields

      case 'isAvailable':
      case 'description':
      case 'name':
      case 'sortOrder':
        return MergePolicy.lastWriteWins; // Low-risk, operational fields

      case 'deletedAt':
        return MergePolicy
            .tombstoneWins; // Deletion is permanent until explicitly restored

      default:
        return MergePolicy
            .manualReviewRequired; // Fallback to safe manual review
    }
  }
}
