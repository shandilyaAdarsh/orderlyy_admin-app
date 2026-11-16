// ── Menu Item Recommendation DTO ─────────────────────────────────────────────
// Admin-side relationship CRUD data model

library;

class RecommendedItemSummaryDto {
  final String id;
  final String name;
  final String? imageUrl;
  final double basePrice;
  final String status;

  const RecommendedItemSummaryDto({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.basePrice,
    required this.status,
  });

  factory RecommendedItemSummaryDto.fromJson(Map<String, dynamic> json) =>
      RecommendedItemSummaryDto(
        id: json['id'] as String,
        name: json['name'] as String,
        imageUrl: json['image_url'] as String?,
        basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'active',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image_url': imageUrl,
        'base_price': basePrice,
        'status': status,
      };
}

class MenuItemRecommendationDto {
  final String id;
  final String tenantId;
  final String? branchId;
  final String sourceMenuItemId;
  final String recommendedMenuItemId;
  final String recommendationType;
  final int priority;
  final bool isActive;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RecommendedItemSummaryDto? recommendedItem;

  const MenuItemRecommendationDto({
    required this.id,
    required this.tenantId,
    this.branchId,
    required this.sourceMenuItemId,
    required this.recommendedMenuItemId,
    required this.recommendationType,
    required this.priority,
    required this.isActive,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.recommendedItem,
  });

  bool get isExclusion => recommendationType == 'dont_recommend';

  String get typeDisplayName {
    switch (recommendationType) {
      case 'complementary':
        return 'Complementary';
      case 'admin_selected':
        return 'Admin Selected';
      case 'complete_meal':
        return 'Complete Meal';
      case 'similar':
        return 'Similar Item';
      case 'popular':
        return 'Popular';
      case 'frequently_bought':
        return 'Frequently Bought';
      case 'dont_recommend':
        return 'Hard Exclusion';
      default:
        return recommendationType;
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 1:
        return 'Low (1)';
      case 2:
        return 'Normal (2)';
      case 3:
        return 'High (3)';
      case 0:
        return 'Legacy (0)';
      default:
        return 'Priority $priority';
    }
  }

  factory MenuItemRecommendationDto.fromJson(Map<String, dynamic> json) =>
      MenuItemRecommendationDto(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        branchId: json['branch_id'] as String?,
        sourceMenuItemId: json['source_menu_item_id'] as String,
        recommendedMenuItemId: json['recommended_menu_item_id'] as String,
        recommendationType: json['recommendation_type'] as String,
        priority: json['priority'] as int? ?? 2,
        isActive: json['is_active'] as bool? ?? true,
        deletedAt: json['deleted_at'] != null
            ? DateTime.tryParse(json['deleted_at'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
        recommendedItem: json['recommended_item'] != null
            ? RecommendedItemSummaryDto.fromJson(
                json['recommended_item'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'branch_id': branchId,
        'source_menu_item_id': sourceMenuItemId,
        'recommended_menu_item_id': recommendedMenuItemId,
        'recommendation_type': recommendationType,
        'priority': priority,
        'is_active': isActive,
        'deleted_at': deletedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'recommended_item': recommendedItem?.toJson(),
      };

  MenuItemRecommendationDto copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? sourceMenuItemId,
    String? recommendedMenuItemId,
    String? recommendationType,
    int? priority,
    bool? isActive,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    RecommendedItemSummaryDto? recommendedItem,
  }) {
    return MenuItemRecommendationDto(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      sourceMenuItemId: sourceMenuItemId ?? this.sourceMenuItemId,
      recommendedMenuItemId:
          recommendedMenuItemId ?? this.recommendedMenuItemId,
      recommendationType: recommendationType ?? this.recommendationType,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recommendedItem: recommendedItem ?? this.recommendedItem,
    );
  }
}
