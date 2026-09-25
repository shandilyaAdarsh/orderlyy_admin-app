// ── Menu Domain DTOs ──────────────────────────────────────────────────────────
// API-compatible. Field names match future backend contract.

library;

// ── Category ──────────────────────────────────────────────────────────────────

class MenuCategoryDto {
  final String id;
  final String tenantId;
  final String? parentId;
  final String name;
  final String? description;
  final String? slug;
  final int sortOrder;
  final bool isActive;
  final String? path;
  final int depth;
  final int versionNum;
  final DateTime? deletedAt;

  const MenuCategoryDto({
    required this.id,
    required this.tenantId,
    this.parentId,
    required this.name,
    this.description,
    this.slug,
    required this.sortOrder,
    required this.isActive,
    this.path,
    this.depth = 0,
    required this.versionNum,
    this.deletedAt,
  });

  factory MenuCategoryDto.fromJson(Map<String, dynamic> json) =>
      MenuCategoryDto(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        parentId: json['parent_id'] as String?,
        name: json['name'] as String,
        description: json['description'] as String?,
        slug: json['slug'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        path: json['path'] as String?,
        depth: json['depth'] as int? ?? 0,
        versionNum: json['version_num'] as int? ?? 1,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
      );

  /// Converts a category name to a URL-safe slug (matches backend slug rules).
  static String slugify(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }

  String get resolvedSlug => slug ?? slugify(name);

  Map<String, dynamic> toJson() => {
    // Omit 'id', 'path', 'depth', 'deleted_at' on insert/update as backend generates/manages them
    'tenant_id': tenantId,
    'parent_id': parentId,
    'name': name,
    'slug': slug ?? slugify(name),
    'description': description,
    'sort_order': sortOrder,
    'is_active': isActive,
    'version_num': versionNum,
  };

  Map<String, dynamic> toJsonWithId() => {
    'id': id,
    'tenant_id': tenantId,
    'parent_id': parentId,
    'name': name,
    'slug': slug ?? slugify(name),
    'description': description,
    'sort_order': sortOrder,
    'is_active': isActive,
    'version_num': versionNum,
  };
}

// ── Menu Item ─────────────────────────────────────────────────────────────────

class MenuItemDto {
  final String id;
  final String tenantId;
  final String categoryId;
  final String name;
  final String? slug;
  final String? description;
  final int
  basePriceAmount; // Operational base price minor units. NOT effective price.
  final String? imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final int prepTimeMinutes;
  final List<String> tags;
  final int versionNum;
  final DateTime? deletedAt;

  const MenuItemDto({
    required this.id,
    required this.tenantId,
    required this.categoryId,
    required this.name,
    this.slug,
    this.description,
    required this.basePriceAmount,
    this.imageUrl,
    required this.isAvailable,
    required this.isVegetarian,
    required this.prepTimeMinutes,
    required this.tags,
    required this.versionNum,
    this.deletedAt,
  });

  factory MenuItemDto.fromJson(Map<String, dynamic> json) {
    final dietaryTags = List<String>.from(json['dietary_tags'] as List? ?? []);
    final isVeg = json['is_veg'] as bool? ?? false;

    return MenuItemDto(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      basePriceAmount: json['base_price_amount'] != null
          ? (json['base_price_amount'] as num).toInt()
          : (((json['base_price'] as num?)?.toDouble() ?? 0.0) * 100).round(),
      imageUrl: json['image_url'] as String?,
      isAvailable: json['status'] == 'active',
      isVegetarian: isVeg,
      prepTimeMinutes: json['prep_time_minutes'] as int? ?? 15,
      tags: dietaryTags,
      versionNum: json['version_num'] as int? ?? 1,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  static String _slugify(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Map<String, dynamic> toJson() {
    return {
      // id, version_num, deleted_at handled by backend on insert
      'tenant_id': tenantId,
      'category_id': categoryId,
      'name': name,
      'slug': slug ?? _slugify(name),
      'description': description,
      'base_price': basePriceAmount / 100.0,
      'base_price_amount': basePriceAmount,
      'image_url': (imageUrl != null && imageUrl!.trim().isEmpty) ? null : imageUrl,
      'status': isAvailable ? 'active' : 'inactive',
      'is_veg': isVegetarian,
      'dietary_tags': tags,
      'prep_time_minutes': prepTimeMinutes,
      'version_num': versionNum, // sent for OCC
    };
  }

  MenuItemDto copyWith({
    String? id,
    String? tenantId,
    String? categoryId,
    String? name,
    String? slug,
    String? description,
    int? basePriceAmount,
    String? imageUrl,
    bool? isAvailable,
    bool? isVegetarian,
    int? prepTimeMinutes,
    List<String>? tags,
    int? versionNum,
    DateTime? deletedAt,
  }) {
    return MenuItemDto(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      basePriceAmount: basePriceAmount ?? this.basePriceAmount,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      tags: tags ?? this.tags,
      versionNum: versionNum ?? this.versionNum,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
