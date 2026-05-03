import 'package:flutter_test/flutter_test.dart';
import 'package:orderlli_admin/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const OrderlliApp());
    expect(find.byType(OrderlliApp), findsOneWidget);
  });
}
