import 'package:flutter_test/flutter_test.dart';

import 'package:opencodemobile/app.dart';

void main() {
  testWidgets('App renders setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenCodeApp());
    expect(find.text('OpenCode Mobile'), findsOneWidget);
  });
}
