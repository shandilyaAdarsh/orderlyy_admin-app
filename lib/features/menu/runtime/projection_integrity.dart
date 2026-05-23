// lib/features/menu/runtime/projection_integrity.dart
import '../domain/entities/menu_snapshot.dart';

class ProjectionIntegrityResult {
  final bool isValid;
  final List<String> errors;

  const ProjectionIntegrityResult({
    required this.isValid,
    required this.errors,
  });
}

class ProjectionIntegrity {
  /// Validates the structural integrity of a MenuSnapshot projection.
  /// Checks for category existence, non-negative pricing, and valid modifier group references.
  static ProjectionIntegrityResult validate(MenuSnapshot snapshot) {
    final errors = <String>[];

    final categoryIds = snapshot.categories.map((c) => c.id).toSet();
    final modifierGroupIds = snapshot.modifierGroups.map((g) => g.id).toSet();

    for (final item in snapshot.items) {
      // 1. Category check
      if (!categoryIds.contains(item.categoryId)) {
        errors.add('MenuItem "${item.name}" (ID: ${item.id}) references non-existent category ID "${item.categoryId}".');
      }

      // 2. Price check
      if (item.price.amountInCents < 0) {
        errors.add('MenuItem "${item.name}" (ID: ${item.id}) has a negative price: ${item.price.amountInCents} cents.');
      }

      // 3. Modifier group check
      for (final groupId in item.modifierGroupIds) {
        if (!modifierGroupIds.contains(groupId)) {
          errors.add('MenuItem "${item.name}" (ID: ${item.id}) references non-existent modifier group ID "$groupId".');
        }
      }
    }

    return ProjectionIntegrityResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}
