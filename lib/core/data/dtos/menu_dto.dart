// ── Menu Domain DTOs ──────────────────────────────────────────────────────────
// API-compatible. Field names match future backend contract.

library;

// ── Category ──────────────────────────────────────────────────────────────────

class MenuCategoryDto {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final int sortOrder;
  final bool isActive;

  const MenuCategoryDto({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    required this.sortOrder,
    required this.isActive,
  });

  factory MenuCategoryDto.fromJson(Map<String, dynamic> json) =>
      MenuCategoryDto(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'name': name,
    'description': description,
    'sort_order': sortOrder,
    'is_active': isActive,
  };
}

// ── Menu Item ─────────────────────────────────────────────────────────────────

class MenuItemDto {
  final String id;
  final String tenantId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final int prepTimeMinutes;
  final List<String> tags;

  const MenuItemDto({
    required this.id,
    required this.tenantId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.isVegetarian,
    required this.prepTimeMinutes,
    required this.tags,
  });

  factory MenuItemDto.fromJson(Map<String, dynamic> json) => MenuItemDto(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    categoryId: json['category_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    price: (json['price'] as num).toDouble(),
    imageUrl: json['image_url'] as String?,
    isAvailable: json['is_available'] as bool? ?? true,
    isVegetarian: json['is_vegetarian'] as bool? ?? false,
    prepTimeMinutes: json['prep_time_minutes'] as int? ?? 15,
    tags: List<String>.from(json['tags'] as List? ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'price': price,
    'image_url': imageUrl,
    'is_available': isAvailable,
    'is_vegetarian': isVegetarian,
    'prep_time_minutes': prepTimeMinutes,
    'tags': tags,
  };
}
