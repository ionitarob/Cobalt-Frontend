import 'package:flutter_test/flutter_test.dart';
import 'package:configtool_cobalt/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CobaltApp());
    expect(find.byType(CobaltApp), findsOneWidget);
  });
}
