import 'package:flutter_test/flutter_test.dart';
import 'package:orderlli_admin/core/data/dtos/menu_dto.dart';

void main() {
  group('MenuItemDto Recommendation Metadata Tests', () {
    test('Default values for recommendation metadata are safe and enabled', () {
      const item = MenuItemDto(
        id: 'item-1',
        tenantId: 'tenant-1',
        categoryId: 'cat-1',
        name: 'Butter Chicken',
        basePriceAmount: 35000,
        imageUrl: null,
        isAvailable: true,
        isVegetarian: false,
        prepTimeMinutes: 20,
        tags: ['non-veg'],
        versionNum: 1,
      );

      expect(item.recommendationEnabled, isTrue);
      expect(item.recommendationTags, isEmpty);
    });

    test('JSON serialization includes recommendation_enabled and normalized recommendation_tags', () {
      const item = MenuItemDto(
        id: 'item-2',
        tenantId: 'tenant-1',
        categoryId: 'cat-1',
        name: 'Tandoori Roti',
        basePriceAmount: 4000,
        imageUrl: null,
        isAvailable: true,
        isVegetarian: true,
        prepTimeMinutes: 10,
        tags: ['veg'],
        recommendationEnabled: true,
        recommendationTags: ['Bread', ' Tandoori ', 'bread', 'CLAY-OVEN', ''],
        versionNum: 1,
      );

      final json = item.toJson();
      expect(json['recommendation_enabled'], isTrue);
      final tags = json['recommendation_tags'] as List<String>;
      expect(tags, containsAll(['bread', 'tandoori', 'clay-oven']));
      expect(tags.length, equals(3)); // Deduplicated and trimmed
      expect(tags.contains(''), isFalse); // Non-empty
    });

    test('JSON deserialization handles missing recommendation fields with safe defaults', () {
      final json = {
        'id': 'item-3',
        'tenant_id': 'tenant-1',
        'category_id': 'cat-1',
        'name': 'Paneer Tikka',
        'base_price_amount': 28000,
        'status': 'active',
        'is_veg': true,
        'prep_time_minutes': 15,
        'dietary_tags': ['veg'],
        'version_num': 1,
      };

      final item = MenuItemDto.fromJson(json);
      expect(item.recommendationEnabled, isTrue);
      expect(item.recommendationTags, isEmpty);
    });

    test('JSON deserialization normalizes incoming recommendation_tags', () {
      final json = {
        'id': 'item-4',
        'tenant_id': 'tenant-1',
        'category_id': 'cat-1',
        'name': 'Garlic Naan',
        'base_price_amount': 6000,
        'status': 'active',
        'is_veg': true,
        'prep_time_minutes': 10,
        'dietary_tags': ['veg'],
        'recommendation_enabled': false,
        'recommendation_tags': ['  GARLIC ', 'Naan', 'garlic', '  ', 'BREAD'],
        'version_num': 1,
      };

      final item = MenuItemDto.fromJson(json);
      expect(item.recommendationEnabled, isFalse);
      expect(item.recommendationTags, equals(['garlic', 'naan', 'bread']));
    });

    test('copyWith updates recommendation fields properly', () {
      const item = MenuItemDto(
        id: 'item-5',
        tenantId: 'tenant-1',
        categoryId: 'cat-1',
        name: 'Dal Makhani',
        basePriceAmount: 22000,
        imageUrl: null,
        isAvailable: true,
        isVegetarian: true,
        prepTimeMinutes: 15,
        tags: ['veg'],
        recommendationEnabled: true,
        recommendationTags: ['lentil'],
        versionNum: 1,
      );

      final updated = item.copyWith(
        recommendationEnabled: false,
        recommendationTags: ['lentil', 'creamy', 'main'],
      );

      expect(updated.recommendationEnabled, isFalse);
      expect(updated.recommendationTags, equals(['lentil', 'creamy', 'main']));
      expect(updated.name, equals('Dal Makhani'));
    });
  });
}
