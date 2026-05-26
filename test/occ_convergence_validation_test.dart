import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:orderlli_admin/features/menu/runtime/occ_conflict_resolver.dart';
import 'package:orderlli_admin/features/menu/domain/entities/menu_snapshot.dart';
import 'package:orderlli_admin/shared/models/money.dart';

void main() {
  final talker = Talker();

  group('OCC Convergence Validation', () {
    late OccConflictResolver resolver;
    late MenuSnapshot baseSnapshot;

    setUp(() {
      resolver = OccConflictResolver(talker);
      baseSnapshot = const MenuSnapshot(
        categories: [MenuCategory(id: 'cat_1', name: 'Burgers', sortOrder: 1)],
        items: [
          MenuItem(
            id: 'item_burger',
            categoryId: 'cat_1',
            name: 'Classic Cheeseburger',
            description: 'Original',
            price: Money(amountInCents: 1000),
            isAvailable: true,
            modifierGroupIds: [],
          ),
          MenuItem(
            id: 'item_fries',
            categoryId: 'cat_1',
            name: 'Fries',
            description: 'Original',
            price: Money(amountInCents: 300),
            isAvailable: true,
            modifierGroupIds: [],
          ),
        ],
        modifierGroups: [],
        taxConfig: TaxConfig(vatRate: 0.10, serviceChargeRate: 0.05),
        snapshotVersion: '10',
      );
    });

    test(
      '1. Deterministic merge output (same conflict replayed -> identical merge result)',
      () {
        final localOptimistic = baseSnapshot.copyWith(
          items: [
            baseSnapshot.items[0].copyWith(
              price: const Money(amountInCents: 1250),
            ),
            baseSnapshot.items[1],
          ],
        );

        final serverAuthoritative = baseSnapshot.copyWith(
          items: [
            baseSnapshot.items[0].copyWith(isAvailable: false),
            baseSnapshot.items[1],
          ],
          snapshotVersion: '11',
        );

        final Set<String> checksums = {};

        for (int i = 0; i < 50; i++) {
          final result = resolver.resolveSnapshotConflict(
            localOptimistic: localOptimistic,
            serverAuthoritative: serverAuthoritative,
            expectedBaseRevision: 10,
            baseSnapshot: baseSnapshot,
            deviceId: 'device-1',
            sessionId: 'session-1',
          );

          final mergedItemsStr = result.reconciledState.items
              .map(
                (i) => '\${i.id}-\${i.price.amountInCents}-\${i.isAvailable}',
              )
              .join('|');
          checksums.add(sha256.convert(utf8.encode(mergedItemsStr)).toString());
        }

        expect(checksums.length, 1);
        print('Deterministic Merge Checksum: \${checksums.first}');
      },
    );

    test(
      '2. Tombstone precedence enforced (deleted entities never resurrect)',
      () {
        // Local deletes item_burger
        final localOptimistic = baseSnapshot.copyWith(
          items: [
            baseSnapshot.items[1], // Only fries remain
          ],
        );

        // Server modified item_burger's price concurrently
        final serverAuthoritative = baseSnapshot.copyWith(
          items: [
            baseSnapshot.items[0].copyWith(
              price: const Money(amountInCents: 1500),
            ),
            baseSnapshot.items[1],
          ],
          snapshotVersion: '11',
        );

        final result = resolver.resolveSnapshotConflict(
          localOptimistic: localOptimistic,
          serverAuthoritative: serverAuthoritative,
          expectedBaseRevision: 10,
          baseSnapshot: baseSnapshot,
          deviceId: 'device-1',
          sessionId: 'session-1',
        );

        // Since MergePolicy for deletedAt is tombstoneWins, item_burger should NOT be in the reconciled state
        expect(
          result.reconciledState.items.any((i) => i.id == 'item_burger'),
          isFalse,
        );
        print('Tombstone precedence enforced safely.');
      },
    );

    test('3. Stale writes rejected safely', () {
      final localOptimistic = baseSnapshot.copyWith(
        items: [
          baseSnapshot.items[0].copyWith(
            price: const Money(amountInCents: 1250),
          ),
          baseSnapshot.items[1],
        ],
      );

      // Server is at 15. The client thought the base was 10, but actually server is at 15
      // and base snapshot is not provided (e.g. lost cache).
      final result = resolver.resolveSnapshotConflict(
        localOptimistic: localOptimistic,
        serverAuthoritative: baseSnapshot.copyWith(snapshotVersion: '15'),
        expectedBaseRevision: 10,
        baseSnapshot: null, // Forces fallback to server state
        deviceId: 'device-1',
        sessionId: 'session-1',
      );

      expect(result.hasConflict, isTrue);
      expect(result.state, OccConflictState.requiresManualReview);
      expect(result.envelope!.conflictFields.contains('ALL'), isTrue);
      expect(result.reconciledState.snapshotVersion, '15');
      print('Stale write rejected gracefully.');
    });

    test(
      '4. Conflict envelopes generated correctly & Manual review conflicts enter CONFLICT_REQUIRES_REVIEW',
      () {
        // Direct collision on price
        final localOptimistic = baseSnapshot.copyWith(
          items: [
            baseSnapshot.items[0].copyWith(
              price: const Money(amountInCents: 1250),
            ),
            baseSnapshot.items[1],
          ],
        );

        final serverAuthoritative = baseSnapshot.copyWith(
          items: [
            baseSnapshot.items[0].copyWith(
              price: const Money(amountInCents: 1500),
            ),
            baseSnapshot.items[1],
          ],
          snapshotVersion: '11',
        );

        final result = resolver.resolveSnapshotConflict(
          localOptimistic: localOptimistic,
          serverAuthoritative: serverAuthoritative,
          expectedBaseRevision: 10,
          baseSnapshot: baseSnapshot,
          deviceId: 'device-1',
          sessionId: 'session-1',
        );

        expect(result.hasConflict, isTrue);
        expect(result.state, OccConflictState.requiresManualReview);
        expect(result.envelope, isNotNull);
        expect(result.envelope!.conflictFields.contains('price'), isTrue);
        expect(result.envelope!.baseRevision, 10);
        expect(result.envelope!.remoteRevision, 11);
        print('Conflict envelope: \${result.envelope!.conflictFields}');
      },
    );

    test(
      '5. Replay after conflict remains deterministic & rebuilds converge correctly',
      () {
        // Simulate a conflict resolution that requires manual review
        final localOptimistic = baseSnapshot.copyWith(
          items: [
            baseSnapshot.items[0].copyWith(
              price: const Money(amountInCents: 1250),
            ),
          ],
        );

        final serverAuthoritative = baseSnapshot.copyWith(
          items: [
            baseSnapshot.items[0].copyWith(
              price: const Money(amountInCents: 1500),
            ),
          ],
          snapshotVersion: '11',
        );

        final result1 = resolver.resolveSnapshotConflict(
          localOptimistic: localOptimistic,
          serverAuthoritative: serverAuthoritative,
          expectedBaseRevision: 10,
          baseSnapshot: baseSnapshot,
          deviceId: 'dev1',
          sessionId: 'sess1',
        );

        final result2 = resolver.resolveSnapshotConflict(
          localOptimistic: localOptimistic,
          serverAuthoritative: serverAuthoritative,
          expectedBaseRevision: 10,
          baseSnapshot: baseSnapshot,
          deviceId: 'dev1',
          sessionId: 'sess1',
        );

        expect(
          result1.envelope!.conflictFields,
          result2.envelope!.conflictFields,
        );
        expect(
          result1.reconciledState.items[0].price.amountInCents,
          result2.reconciledState.items[0].price.amountInCents,
        );

        print('Rebuild convergence is deterministic.');
      },
    );
  });
}
