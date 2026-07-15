import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/settings_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/project_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (e) {
    debugPrint('WidgetsFlutterBinding initialization error: $e');
  }

  final settingsProvider = SettingsProvider();
  try {
    await settingsProvider.loadSettings();
  } catch (e, stackTrace) {
    debugPrint('Error loading settings on startup: $e\n$stackTrace');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: const OpenCodeApp(),
    ),
  );
}
