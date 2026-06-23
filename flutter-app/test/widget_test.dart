import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aaura/main.dart';

void main() {
  testWidgets('AAURA app boots to landing screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AauraApp());

    // Don't pumpAndSettle: the landing screen has an intentional looping
    // background animation that never settles. A few pumps is enough to
    // render the initial frame.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.text('AAURA'), findsOneWidget);
    expect(find.text('CHAT WITH SHAMS'), findsOneWidget);
  });
}
