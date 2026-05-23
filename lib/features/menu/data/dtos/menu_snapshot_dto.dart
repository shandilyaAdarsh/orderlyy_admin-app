// lib/features/menu/data/dtos/menu_snapshot_dto.dart
import '../../../../shared/models/money.dart';
import '../../domain/entities/menu_snapshot.dart';

class MenuCategoryDto {
  final String id;
  final String name;
  final int sortOrder;

  const MenuCategoryDto({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  factory MenuCategoryDto.fromJson(Map<String, dynamic> json) {
    return MenuCategoryDto(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sort_order': sortOrder,
      };

  MenuCategory toDomain() => MenuCategory(
        id: id,
        name: name,
        sortOrder: sortOrder,
      );
}

class MenuItemDto {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final int priceInCents;
  final bool isAvailable;
  final List<String> modifierGroupIds;

  const MenuItemDto({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.priceInCents,
    required this.isAvailable,
    required this.modifierGroupIds,
  });

  factory MenuItemDto.fromJson(Map<String, dynamic> json) {
    return MenuItemDto(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      priceInCents: json['price_in_cents'] as int? ?? json['price'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      modifierGroupIds: List<String>.from(json['modifier_group_ids'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'price_in_cents': priceInCents,
        'is_available': isAvailable,
        'modifier_group_ids': modifierGroupIds,
      };

  MenuItem toDomain() => MenuItem(
        id: id,
        categoryId: categoryId,
        name: name,
        description: description,
        price: Money(amountInCents: priceInCents),
        isAvailable: isAvailable,
        modifierGroupIds: modifierGroupIds,
      );
}

class ModifierOptionDto {
  final String id;
  final String name;
  final int priceInCents;

  const ModifierOptionDto({
    required this.id,
    required this.name,
    required this.priceInCents,
  });

  factory ModifierOptionDto.fromJson(Map<String, dynamic> json) {
    return ModifierOptionDto(
      id: json['id'] as String,
      name: json['name'] as String,
      priceInCents: json['price_in_cents'] as int? ?? json['price'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price_in_cents': priceInCents,
      };

  ModifierOption toDomain() => ModifierOption(
        id: id,
        name: name,
        price: Money(amountInCents: priceInCents),
      );
}

class ModifierGroupDto {
  final String id;
  final String name;
  final List<ModifierOptionDto> options;

  const ModifierGroupDto({
    required this.id,
    required this.name,
    required this.options,
  });

  factory ModifierGroupDto.fromJson(Map<String, dynamic> json) {
    return ModifierGroupDto(
      id: json['id'] as String,
      name: json['name'] as String,
      options: (json['options'] as List? ?? [])
          .map((e) => ModifierOptionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'options': options.map((e) => e.toJson()).toList(),
      };

  ModifierGroup toDomain() => ModifierGroup(
        id: id,
        name: name,
        options: options.map((e) => e.toDomain()).toList(),
      );
}

class TaxConfigDto {
  final double vatRate;
  final double serviceChargeRate;

  const TaxConfigDto({
    required this.vatRate,
    required this.serviceChargeRate,
  });

  factory TaxConfigDto.fromJson(Map<String, dynamic> json) {
    return TaxConfigDto(
      vatRate: (json['vat_rate'] as num? ?? 0.0).toDouble(),
      serviceChargeRate: (json['service_charge_rate'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'vat_rate': vatRate,
        'service_charge_rate': serviceChargeRate,
      };

  TaxConfig toDomain() => TaxConfig(
        vatRate: vatRate,
        serviceChargeRate: serviceChargeRate,
      );
}

class MenuSnapshotDto {
  final List<MenuCategoryDto> categories;
  final List<MenuItemDto> items;
  final List<ModifierGroupDto> modifierGroups;
  final TaxConfigDto taxConfig;
  final Map<String, dynamic> metadata;
  final Map<String, bool> availabilityOverlay;
  final String? etag;
  final String? snapshotVersion;
  final DateTime? generatedAt;
  final String branchId;

  const MenuSnapshotDto({
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

  factory MenuSnapshotDto.fromJson(Map<String, dynamic> json) {
    return MenuSnapshotDto(
      categories: (json['categories'] as List? ?? [])
          .map((e) => MenuCategoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List? ?? [])
          .map((e) => MenuItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      modifierGroups: (json['modifier_groups'] as List? ?? [])
          .map((e) => ModifierGroupDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      taxConfig: TaxConfigDto.fromJson(
          json['tax_configs'] as Map<String, dynamic>? ??
              json['tax_config'] as Map<String, dynamic>? ??
              {}),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      availabilityOverlay: (json['availability_overlay'] as Map? ??
              json['availabilityOverlay'] as Map? ??
              const {})
          .map((k, v) => MapEntry(k.toString(), v as bool)),
      etag: json['etag'] as String?,
      snapshotVersion: json['snapshot_version'] as String? ?? json['version'] as String?,
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'] as String)
          : null,
      branchId: json['branch_id'] as String? ?? 'mock_branch',
    );
  }

  Map<String, dynamic> toJson() => {
        'categories': categories.map((e) => e.toJson()).toList(),
        'items': items.map((e) => e.toJson()).toList(),
        'modifier_groups': modifierGroups.map((e) => e.toJson()).toList(),
        'tax_configs': taxConfig.toJson(),
        'metadata': metadata,
        'availability_overlay': availabilityOverlay,
        'etag': etag,
        'snapshot_version': snapshotVersion,
        'generated_at': generatedAt?.toIso8601String(),
        'branch_id': branchId,
      };

  MenuSnapshot toDomain() => MenuSnapshot(
        categories: categories.map((e) => e.toDomain()).toList(),
        items: items.map((e) => e.toDomain()).toList(),
        modifierGroups: modifierGroups.map((e) => e.toDomain()).toList(),
        taxConfig: taxConfig.toDomain(),
        metadata: metadata,
        availabilityOverlay: availabilityOverlay,
        etag: etag,
        snapshotVersion: snapshotVersion,
        generatedAt: generatedAt,
        branchId: branchId,
      );
}
