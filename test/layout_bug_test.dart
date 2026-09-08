import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orderlli_admin/main.dart'; // adjust path to your main

void main() {
  testWidgets('App starts without layout exception', (
    WidgetTester tester,
  ) async {
    try {
      await tester.pumpWidget(const ProviderScope(child: OrderlyyApp()));
      await tester.pumpAndSettle();
    } catch (e, st) {
      debugPrint('CAUGHT EXCEPTION: $e');
      debugPrint('STACKTRACE: $st');
      rethrow;
    }
  });
}
