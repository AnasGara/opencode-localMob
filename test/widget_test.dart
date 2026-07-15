import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opencodemobile/app.dart';
import 'package:opencodemobile/providers/settings_provider.dart';
import 'package:opencodemobile/providers/chat_provider.dart';
import 'package:opencodemobile/providers/project_provider.dart';

void main() {
  testWidgets('App renders home screen directly in free mode', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settingsProvider = SettingsProvider();
    await settingsProvider.loadSettings();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ],
        child: const OpenCodeApp(),
      ),
    );
    expect(find.text('Bou3orrif'), findsAtLeast(1));
  });
}
