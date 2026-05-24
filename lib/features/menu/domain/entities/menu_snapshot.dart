// lib/features/menu/domain/entities/menu_snapshot.dart
import 'package:equatable/equatable.dart';
import '../../../../shared/models/money.dart';
import '../../../orders/domain/entities/menu_product.dart' as orders_entities;

class MenuCategory extends Equatable {
  final String id;
  final String name;
  final int sortOrder;
  final DateTime? deletedAt;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [id, name, sortOrder, deletedAt];
}

class MenuItem extends Equatable {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final Money price;
  final bool isAvailable;
  final List<String> modifierGroupIds;
  final DateTime? deletedAt;

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.isAvailable,
    required this.modifierGroupIds,
    this.deletedAt,
  });

  MenuItem copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    Money? price,
    bool? isAvailable,
    List<String>? modifierGroupIds,
    DateTime? deletedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      modifierGroupIds: modifierGroupIds ?? this.modifierGroupIds,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [id, categoryId, name, description, price, isAvailable, modifierGroupIds, deletedAt];
}

class ModifierGroup extends Equatable {
  final String id;
  final String name;
  final List<ModifierOption> options;
  final DateTime? deletedAt;

  const ModifierGroup({
    required this.id,
    required this.name,
    required this.options,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [id, name, options, deletedAt];
}

class ModifierOption extends Equatable {
  final String id;
  final String name;
  final Money price;
  final DateTime? deletedAt;

  const ModifierOption({
    required this.id,
    required this.name,
    required this.price,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [id, name, price, deletedAt];
}

class TaxConfig extends Equatable {
  final double vatRate;
  final double serviceChargeRate;

  const TaxConfig({
    required this.vatRate,
    required this.serviceChargeRate,
  });

  @override
  List<Object?> get props => [vatRate, serviceChargeRate];
}

class MenuSnapshot extends Equatable {
  final Map<String, dynamic> metadata;
  final List<MenuCategory> categories;
  final List<MenuItem> items;
  final List<ModifierGroup> modifierGroups;
  final TaxConfig taxConfig;
  final Map<String, bool> availabilityOverlay;
  final String? etag;
  final String? snapshotVersion;
  final DateTime? generatedAt;
  final String branchId;

  const MenuSnapshot({
    required this.categories,
    required this.items,
    required this.modifierGroups,
    required this.taxConfig,
    this.metadata = const {},
    this.availabilityOverlay = const {},
    this.etag,
    this.snapshotVersion,
    this.generatedAt,
    this.branchId = 'mock_branch',
  });

  MenuSnapshot copyWith({
    Map<String, dynamic>? metadata,
    List<MenuCategory>? categories,
    List<MenuItem>? items,
    List<ModifierGroup>? modifierGroups,
    TaxConfig? taxConfig,
    Map<String, bool>? availabilityOverlay,
    String? etag,
    String? snapshotVersion,
    DateTime? generatedAt,
    String? branchId,
  }) {
    return MenuSnapshot(
      metadata: metadata ?? this.metadata,
      categories: categories ?? this.categories,
      items: items ?? this.items,
      modifierGroups: modifierGroups ?? this.modifierGroups,
      taxConfig: taxConfig ?? this.taxConfig,
      availabilityOverlay: availabilityOverlay ?? this.availabilityOverlay,
      etag: etag ?? this.etag,
      snapshotVersion: snapshotVersion ?? this.snapshotVersion,
      generatedAt: generatedAt ?? this.generatedAt,
      branchId: branchId ?? this.branchId,
    );
  }

  @override
  List<Object?> get props => [
        metadata,
        categories,
        items,
        modifierGroups,
        taxConfig,
        availabilityOverlay,
        etag,
        snapshotVersion,
        generatedAt,
        branchId,
      ];

  /// Helper to convert snapshot items to legacy domain models for UI compatibility
  List<orders_entities.MenuProduct> toMenuProducts() {
    final products = <orders_entities.MenuProduct>[];

    final categoryMap = {for (final cat in categories) cat.id: cat.name};
    final groupMap = {for (final group in modifierGroups) group.id: group};

    for (final item in items) {
      final categoryName = categoryMap[item.categoryId] ?? 'All';

      // Gather modifier options from groups assigned to this item
      final availableModifiers = <orders_entities.ModifierOption>[];
      for (final groupId in item.modifierGroupIds) {
        final group = groupMap[groupId];
        if (group != null) {
          for (final opt in group.options) {
            availableModifiers.add(
              orders_entities.ModifierOption(
                id: opt.id,
                name: opt.name,
                price: opt.price,
              ),
            );
          }
        }
      }

      // We only append if item is available or we let UI disable unavailable items
      // (OrderEditorScreen filters or styles unavailable items based on isAvailable)
      // Since availability overlay will dynamically toggle isAvailable, we keep all products but carry availability status
      // We will handle availability overlays in state management.
      products.add(
        orders_entities.MenuProduct(
          id: item.id,
          name: item.name,
          price: item.price,
          category: categoryName,
          availableModifiers: availableModifiers,
        ),
      );
    }

    return products;
  }
}
