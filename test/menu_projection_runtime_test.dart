// test/menu_projection_runtime_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import 'package:orderlli_admin/shared/models/money.dart';
import 'package:orderlli_admin/core/network/dio_client.dart';
import 'package:orderlli_admin/core/network/network_info.dart';
import 'package:orderlli_admin/core/network/network_providers.dart';
import 'package:orderlli_admin/core/network/sync_state.dart';
import 'package:orderlli_admin/core/providers/repository_providers.dart';

import 'package:orderlli_admin/features/menu/domain/entities/menu_snapshot.dart';
import 'package:orderlli_admin/features/menu/domain/repositories/menu_repository.dart';
import 'package:orderlli_admin/features/menu/runtime/projection_reconciliation.dart';
import 'package:orderlli_admin/features/menu/runtime/projection_integrity.dart';
import 'package:orderlli_admin/features/menu/runtime/modifier_resolver.dart';
import 'package:orderlli_admin/features/menu/runtime/snapshot_migration.dart';
import 'package:orderlli_admin/features/menu/presentation/state/menu_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final baseSnapshot = MenuSnapshot(
    categories: const [
      MenuCategory(id: 'cat_1', name: 'Burgers', sortOrder: 1),
      MenuCategory(id: 'cat_2', name: 'Drinks', sortOrder: 2),
    ],
    items: [
      const MenuItem(
        id: 'item_burger',
        categoryId: 'cat_1',
        name: 'Classic Burger',
        description: 'Cheesy',
        price: Money(amountInCents: 1000),
        isAvailable: true,
        modifierGroupIds: ['group_1'],
      ),
      const MenuItem(
        id: 'item_cola',
        categoryId: 'cat_2',
        name: 'Cola',
        description: 'Fizz',
        price: Money(amountInCents: 200),
        isAvailable: true,
        modifierGroupIds: [],
      ),
    ],
    modifierGroups: const [
      ModifierGroup(
        id: 'group_1',
        name: 'Add-ons',
        options: [
          ModifierOption(id: 'opt_cheese', name: 'Cheese', price: Money(amountInCents: 100)),
        ],
      )
    ],
    taxConfig: const TaxConfig(vatRate: 0.10, serviceChargeRate: 0.05),
    branchId: 'br_1',
    snapshotVersion: 'v2.0.0',
  );

  group('ProjectionReconciliation Tests', () {
    test('reconcile overrides isAvailable correctly based on availabilityOverlay', () {
      final overlay = {'item_burger': false};
      final reconciled = ProjectionReconciliation.reconcile(
        snapshot: baseSnapshot,
        availabilityOverlay: overlay,
      );

      final burger = reconciled.items.firstWhere((i) => i.id == 'item_burger');
      final cola = reconciled.items.firstWhere((i) => i.id == 'item_cola');

      expect(burger.isAvailable, isFalse);
      expect(cola.isAvailable, isTrue);
    });
  });

  group('ProjectionIntegrity Tests', () {
    test('valid snapshot passes validation', () {
      final result = ProjectionIntegrity.validate(baseSnapshot);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('invalid category reference returns validation errors', () {
      final invalidSnapshot = baseSnapshot.copyWith(
        items: [
          const MenuItem(
            id: 'item_bad',
            categoryId: 'cat_invalid',
            name: 'Bad Category',
            description: '',
            price: Money(amountInCents: 500),
            isAvailable: true,
            modifierGroupIds: [],
          )
        ],
      );

      final result = ProjectionIntegrity.validate(invalidSnapshot);
      expect(result.isValid, isFalse);
      expect(result.errors[0], contains('references non-existent category ID'));
    });

    test('negative pricing returns validation errors', () {
      final invalidSnapshot = baseSnapshot.copyWith(
        items: [
          const MenuItem(
            id: 'item_bad',
            categoryId: 'cat_1',
            name: 'Bad Price',
            description: '',
            price: Money(amountInCents: -100),
            isAvailable: true,
            modifierGroupIds: [],
          )
        ],
      );

      final result = ProjectionIntegrity.validate(invalidSnapshot);
      expect(result.isValid, isFalse);
      expect(result.errors[0], contains('has a negative price'));
    });

    test('invalid modifier group references return validation errors', () {
      final invalidSnapshot = baseSnapshot.copyWith(
        items: [
          const MenuItem(
            id: 'item_bad',
            categoryId: 'cat_1',
            name: 'Bad Modifier Group',
            description: '',
            price: Money(amountInCents: 500),
            isAvailable: true,
            modifierGroupIds: ['group_invalid'],
          )
        ],
      );

      final result = ProjectionIntegrity.validate(invalidSnapshot);
      expect(result.isValid, isFalse);
      expect(result.errors[0], contains('references non-existent modifier group ID'));
    });
  });

  group('ModifierResolver Tests', () {
    test('resolveGroupsForItem resolves list of modifier groups correctly', () {
      final burger = baseSnapshot.items.firstWhere((i) => i.id == 'item_burger');
      final resolved = ModifierResolver.resolveGroupsForItem(
        item: burger,
        allGroups: baseSnapshot.modifierGroups,
      );

      expect(resolved.length, 1);
      expect(resolved[0].name, 'Add-ons');
    });

    test('validateSelection checks if selected option exists in allowed groups', () {
      final burger = baseSnapshot.items.firstWhere((i) => i.id == 'item_burger');
      
      final valid = ModifierResolver.validateSelection(
        item: burger,
        allGroups: baseSnapshot.modifierGroups,
        selectedOptionIds: ['opt_cheese'],
      );
      expect(valid, isTrue);

      final invalid = ModifierResolver.validateSelection(
        item: burger,
        allGroups: baseSnapshot.modifierGroups,
        selectedOptionIds: ['opt_nonexistent'],
      );
      expect(invalid, isFalse);
    });
  });

  group('SnapshotMigration Tests', () {
    late MockMenuRepository mockRepo;
    late Talker talker;
    late SnapshotMigration migration;

    setUp(() {
      mockRepo = MockMenuRepository();
      talker = Talker();
      migration = SnapshotMigration(repository: mockRepo, talker: talker);
    });

    test('verifyAndMigrate returns true and does not clear cache if version matches', () async {
      mockRepo.cachedSnapshot = baseSnapshot;

      final success = await migration.verifyAndMigrate('br_1');
      expect(success, isTrue);
      expect(mockRepo.clearCacheCalled, isFalse);
    });

    test('verifyAndMigrate clears cache and returns false if version mismatches', () async {
      final oldSnapshot = baseSnapshot.copyWith(snapshotVersion: 'v1.0.0');
      mockRepo.cachedSnapshot = oldSnapshot;

      final success = await migration.verifyAndMigrate('br_1');
      expect(success, isFalse);
      expect(mockRepo.clearCacheCalled, isTrue);
    });
  });
}

class MockMenuRepository implements MenuRepository {
  MenuSnapshot? cachedSnapshot;
  bool clearCacheCalled = false;
  Map<String, bool> cachedOverlay = {};

  @override
  Future<MenuSnapshot> getMenuSnapshot({required String branchId, bool forceRefresh = false}) async {
    return cachedSnapshot!;
  }

  @override
  Future<Map<String, bool>> getItemAvailability({required String branchId}) async {
    return {};
  }

  @override
  Future<void> saveMenuSnapshot(MenuSnapshot snapshot) async {
    cachedSnapshot = snapshot;
  }

  @override
  Future<MenuSnapshot?> getCachedMenuSnapshot(String branchId) async {
    return cachedSnapshot;
  }

  @override
  Future<void> saveAvailabilityOverlay(String branchId, Map<String, bool> overlay) async {
    cachedOverlay = overlay;
  }

  @override
  Future<Map<String, bool>> getCachedAvailabilityOverlay(String branchId) async {
    return cachedOverlay;
  }

  @override
  Future<void> clearCache(String branchId) async {
    clearCacheCalled = true;
  }
}
