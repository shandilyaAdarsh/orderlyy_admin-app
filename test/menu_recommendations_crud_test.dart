// ── Menu Recommendations CRUD Unit Tests ────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:orderlli_admin/core/data/dtos/menu_recommendation_dto.dart';
import 'package:orderlli_admin/core/providers/menu_recommendations_provider.dart';

void main() {
  group('MenuItemRecommendationDto Tests', () {
    test('Canonical recommendation types and properties serialize and deserialize correctly', () {
      final json = {
        'id': 'rec-1',
        'tenant_id': 'tenant-100',
        'branch_id': 'branch-200',
        'source_menu_item_id': 'item-source-1',
        'recommended_menu_item_id': 'item-target-2',
        'recommendation_type': 'complementary',
        'priority': 3,
        'is_active': true,
        'deleted_at': null,
        'created_at': '2026-09-26T12:00:00.000Z',
        'updated_at': '2026-09-26T12:00:00.000Z',
        'recommended_item': {
          'id': 'item-target-2',
          'name': 'Garlic Bread',
          'image_url': 'https://example.com/gb.jpg',
          'base_price': 5.5,
          'status': 'active',
        },
      };

      final dto = MenuItemRecommendationDto.fromJson(json);

      expect(dto.id, equals('rec-1'));
      expect(dto.tenantId, equals('tenant-100'));
      expect(dto.branchId, equals('branch-200'));
      expect(dto.sourceMenuItemId, equals('item-source-1'));
      expect(dto.recommendedMenuItemId, equals('item-target-2'));
      expect(dto.recommendationType, equals('complementary'));
      expect(dto.priority, equals(3));
      expect(dto.isActive, isTrue);
      expect(dto.isExclusion, isFalse);
      expect(dto.typeDisplayName, equals('Complementary'));
      expect(dto.priorityDisplayName, equals('High (3)'));
      expect(dto.recommendedItem?.name, equals('Garlic Bread'));
      expect(dto.recommendedItem?.basePrice, equals(5.5));

      final serialized = dto.toJson();
      expect(serialized['recommendation_type'], equals('complementary'));
      expect(serialized['priority'], equals(3));
      expect(serialized['is_active'], isTrue);
    });

    test('dont_recommend is recognized as Hard Exclusion', () {
      final json = {
        'id': 'rec-ex-1',
        'tenant_id': 'tenant-100',
        'branch_id': null,
        'source_menu_item_id': 'item-source-1',
        'recommended_menu_item_id': 'item-target-99',
        'recommendation_type': 'dont_recommend',
        'priority': 2,
        'is_active': true,
        'deleted_at': null,
      };

      final dto = MenuItemRecommendationDto.fromJson(json);

      expect(dto.isExclusion, isTrue);
      expect(dto.typeDisplayName, equals('Hard Exclusion'));
      expect(dto.priorityDisplayName, equals('Normal (2)'));
    });

    test('Priority levels map correctly to display strings including legacy 0', () {
      expect(
        const MenuItemRecommendationDto(
          id: '1',
          tenantId: 't',
          sourceMenuItemId: 's',
          recommendedMenuItemId: 'r',
          recommendationType: 'complementary',
          priority: 1,
          isActive: true,
        ).priorityDisplayName,
        equals('Low (1)'),
      );

      expect(
        const MenuItemRecommendationDto(
          id: '2',
          tenantId: 't',
          sourceMenuItemId: 's',
          recommendedMenuItemId: 'r',
          recommendationType: 'complementary',
          priority: 2,
          isActive: true,
        ).priorityDisplayName,
        equals('Normal (2)'),
      );

      expect(
        const MenuItemRecommendationDto(
          id: '3',
          tenantId: 't',
          sourceMenuItemId: 's',
          recommendedMenuItemId: 'r',
          recommendationType: 'complementary',
          priority: 3,
          isActive: true,
        ).priorityDisplayName,
        equals('High (3)'),
      );

      expect(
        const MenuItemRecommendationDto(
          id: '0',
          tenantId: 't',
          sourceMenuItemId: 's',
          recommendedMenuItemId: 'r',
          recommendationType: 'complementary',
          priority: 0,
          isActive: true,
        ).priorityDisplayName,
        equals('Legacy (0)'),
      );
    });

    test('copyWith updates fields correctly', () {
      const original = MenuItemRecommendationDto(
        id: 'rec-1',
        tenantId: 'tenant-1',
        sourceMenuItemId: 'item-1',
        recommendedMenuItemId: 'item-2',
        recommendationType: 'similar',
        priority: 1,
        isActive: true,
      );

      final updated = original.copyWith(
        priority: 3,
        recommendationType: 'complete_meal',
        isActive: false,
      );

      expect(updated.id, equals('rec-1'));
      expect(updated.priority, equals(3));
      expect(updated.recommendationType, equals('complete_meal'));
      expect(updated.isActive, isFalse);
    });
  });

  group('MenuItemRecommendationsState Filtering Tests', () {
    test('State filters recommended with vs dont recommend with correctly', () {
      final rec1 = const MenuItemRecommendationDto(
        id: 'r1',
        tenantId: 't',
        sourceMenuItemId: 's',
        recommendedMenuItemId: 'target-1',
        recommendationType: 'complementary',
        priority: 2,
        isActive: true,
      );

      final rec2Inactive = const MenuItemRecommendationDto(
        id: 'r2',
        tenantId: 't',
        sourceMenuItemId: 's',
        recommendedMenuItemId: 'target-2',
        recommendationType: 'admin_selected',
        priority: 3,
        isActive: false,
      );

      final exclusion1 = const MenuItemRecommendationDto(
        id: 'e1',
        tenantId: 't',
        sourceMenuItemId: 's',
        recommendedMenuItemId: 'target-3',
        recommendationType: 'dont_recommend',
        priority: 2,
        isActive: true,
      );

      final exclusion2Inactive = const MenuItemRecommendationDto(
        id: 'e2',
        tenantId: 't',
        sourceMenuItemId: 's',
        recommendedMenuItemId: 'target-4',
        recommendationType: 'dont_recommend',
        priority: 1,
        isActive: false,
      );

      final state = MenuItemRecommendationsState(
        recommendations: [rec1, rec2Inactive, exclusion1, exclusion2Inactive],
      );

      expect(state.recommendedWith.length, equals(2));
      expect(state.activeRecommendedWith.length, equals(1));
      expect(state.activeRecommendedWith.first.id, equals('r1'));
      expect(state.inactiveRecommendedWith.length, equals(1));
      expect(state.inactiveRecommendedWith.first.id, equals('r2'));

      expect(state.dontRecommendWith.length, equals(2));
      expect(state.activeDontRecommendWith.length, equals(1));
      expect(state.activeDontRecommendWith.first.id, equals('e1'));
      expect(state.inactiveDontRecommendWith.length, equals(1));
      expect(state.inactiveDontRecommendWith.first.id, equals('e2'));
    });
  });
}
