import 'package:flutter_test/flutter_test.dart';

import 'package:bom_dia_zap_app/main.dart';

void main() {
  testWidgets('App renders the home screen app bar', (WidgetTester tester) async {
    await tester.pumpWidget(const BomDiaZapApp());

    expect(find.text('Bom Dia Zap'), findsOneWidget);
  });
}
