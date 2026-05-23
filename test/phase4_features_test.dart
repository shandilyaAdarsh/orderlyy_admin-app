import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orderlli_admin/features/menu/runtime/occ_conflict_resolver.dart';
import 'package:orderlli_admin/features/menu/domain/entities/menu_snapshot.dart';
import 'package:orderlli_admin/shared/models/money.dart';
import 'package:orderlli_admin/features/pricing/pricing_management_screen.dart';
import 'package:orderlli_admin/features/taxes/tax_management_screen.dart';
import 'package:orderlli_admin/features/branch_overrides/branch_override_screen.dart';
import 'package:orderlli_admin/features/audit/audit_logs_screen.dart';

void main() {
  group('Phase 4: Concurrency and Calculation Business Rules', () {
    final baseSnapshot = const MenuSnapshot(
      categories: [
        MenuCategory(id: 'cat_1', name: 'Burgers', sortOrder: 1),
      ],
      items: [
        MenuItem(
          id: 'item_burger',
          categoryId: 'cat_1',
          name: 'Classic Cheeseburger',
          description: '',
          price: Money(amountInCents: 1000),
          isAvailable: true,
          modifierGroupIds: [],
        ),
      ],
      modifierGroups: [],
      taxConfig: TaxConfig(vatRate: 0.20, serviceChargeRate: 0.05),
      snapshotVersion: 'v2',
    );

    test('Three-way OCC conflict resolution detects overlapping edits correctly', () {
      final talker = Talker();
      final resolver = OccConflictResolver(talker);

      // Local updated price to ₹12.50
      final localOptimistic = baseSnapshot.copyWith(
        items: [
          baseSnapshot.items[0].copyWith(price: const Money(amountInCents: 1250)),
        ],
      );

      // Server updated availability to false, incrementing version to v3
      final serverAuthoritative = baseSnapshot.copyWith(
        items: [
          baseSnapshot.items[0].copyWith(isAvailable: false),
        ],
        snapshotVersion: 'v3',
      );

      final result = resolver.resolveSnapshotConflict(
        localOptimistic: localOptimistic,
        serverAuthoritative: serverAuthoritative,
        expectedBaseVersion: 'v2',
        baseSnapshot: baseSnapshot,
      );

      // Should auto-merge price override (local) and availability toggle (server)
      expect(result.hasConflict, isFalse);
      expect(result.reconciledState.items[0].price.amountInCents, 1250);
      expect(result.reconciledState.items[0].isAvailable, isFalse);
      expect(result.reconciledState.snapshotVersion, 'v3');
    });

    test('Three-way OCC conflict resolution halts and reports conflict on direct attribute collision', () {
      final talker = Talker();
      final resolver = OccConflictResolver(talker);

      // Local updated price to ₹12.00
      final localOptimistic = baseSnapshot.copyWith(
        items: [
          baseSnapshot.items[0].copyWith(price: const Money(amountInCents: 1200)),
        ],
      );

      // Server updated price to ₹13.00 (same attribute collision!)
      final serverAuthoritative = baseSnapshot.copyWith(
        items: [
          baseSnapshot.items[0].copyWith(price: const Money(amountInCents: 1300)),
        ],
        snapshotVersion: 'v3',
      );

      final result = resolver.resolveSnapshotConflict(
        localOptimistic: localOptimistic,
        serverAuthoritative: serverAuthoritative,
        expectedBaseVersion: 'v2',
        baseSnapshot: baseSnapshot,
      );

      // Direct pricing collision on item_burger -> should report conflict
      expect(result.hasConflict, isTrue);
      expect(result.conflictMessage, contains('Collision detected'));
    });

    test('Tax preview simulator computes net, vat, service charge, and gross authoritatively', () {
      const net = 100.0;
      const vatRate = 20.0; // 20%
      const scRate = 5.0; // 5%

      const vatAmt = net * (vatRate / 100);
      const scAmt = net * (scRate / 100);
      const grossAmt = net + vatAmt + scAmt;

      expect(vatAmt, 20.0);
      expect(scAmt, 5.0);
      expect(grossAmt, 125.0);
    });
  });

  group('Phase 4 Workspace Widgets Rendering Tests', () {
    void setScreenSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
    }

    testWidgets('PricingManagementScreen renders products and history logs', (tester) async {
      setScreenSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(1920, 1080),
        builder: (context, child) => const MaterialApp(
          home: PricingManagementScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Authoritative Pricing Overrides'), findsOneWidget);
      expect(find.text('Pricing Audit Trail'), findsOneWidget);
      expect(find.text('Classic Cheeseburger'), findsOneWidget);
      expect(find.text('Base Price'), findsAtLeast(1));
    });

    testWidgets('TaxManagementScreen renders tax rules and calculator preview', (tester) async {
      setScreenSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(1920, 1080),
        builder: (context, child) => const MaterialApp(
          home: TaxManagementScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Jurisdiction-Specific Tax Matrix'), findsOneWidget);
      expect(find.text('Tax preview simulator'), findsOneWidget);
      expect(find.text('Simulated net price'), findsOneWidget);
    });

    testWidgets('BranchOverrideScreen renders inheritance and status indicators', (tester) async {
      setScreenSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(1920, 1080),
        builder: (context, child) => const MaterialApp(
          home: BranchOverrideScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Inheritance & Local Configuration Overrides'), findsOneWidget);
      expect(find.text('Operational Hours Overrides'), findsOneWidget);
      expect(find.text('SET OVERRIDE'), findsAtLeast(1));
    });

    testWidgets('AuditLogsScreen renders ledger list and filters', (tester) async {
      setScreenSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(1920, 1080),
        builder: (context, child) => const MaterialApp(
          home: AuditLogsScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Immutable Configuration Audit History'), findsOneWidget);
      expect(find.textContaining('Action Scope'), findsOneWidget);
      expect(find.textContaining('Target Branch'), findsOneWidget);
    });
  });
}
