import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opencodemobile/app.dart';
import 'package:opencodemobile/providers/settings_provider.dart';

void main() {
  testWidgets('App renders setup screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settingsProvider = SettingsProvider();
    await settingsProvider.loadSettings();

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settingsProvider,
        child: const OpenCodeApp(),
      ),
    );
    expect(find.text('Bou3orrif'), findsOneWidget);
  });
}
