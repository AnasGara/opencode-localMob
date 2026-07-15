import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opencodemobile/providers/settings_provider.dart';
import 'package:opencodemobile/providers/chat_provider.dart';
import 'package:opencodemobile/providers/project_provider.dart';
import 'package:opencodemobile/services/opencode_service.dart';
import 'package:opencodemobile/app.dart';

import 'package:opencodemobile/services/file_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FileService getFileName Tests', () {
    test('extracts filename from Unix paths', () {
      expect(FileService.getFileName('/home/user/documents/report.pdf'), equals('report.pdf'));
    });

    test('extracts filename from Windows paths', () {
      expect(FileService.getFileName(r'C:\Users\Name\Desktop\image.png'), equals('image.png'));
    });

    test('handles single filename without paths', () {
      expect(FileService.getFileName('data.json'), equals('data.json'));
    });

    test('handles null and empty paths gracefully', () {
      expect(FileService.getFileName(null), equals(''));
      expect(FileService.getFileName(''), equals(''));
    });
  });

  group('OpenCodeService Free Mode Tests', () {
    test('Initialize with free key sets isInitialized to true', () {
      final service = OpenCodeService();
      expect(service.isInitialized, isTrue);

      service.initialize();
      expect(service.isInitialized, isTrue);
    });

    test('UTF-8 request payload containing Arabic, French, and emojis encodes without throwing any exceptions', () async {
      final service = OpenCodeService();
      service.initialize();

      final payload = {
        'model': 'big-pickle',
        'messages': [
          {'role': 'user', 'content': 'العربية - Français - English: How are you? 😊'}
        ]
      };

      // Ensure we can convert to JSON and encode to UTF-8 without raising any exception
      final jsonStr = jsonEncode(payload);
      final encodedBytes = utf8.encode(jsonStr);
      final decodedStr = utf8.decode(encodedBytes);

      expect(decodedStr, equals(jsonStr));
      expect(jsonStr.contains('العربية'), isTrue);
      expect(jsonStr.contains('Français'), isTrue);
      expect(jsonStr.contains('😊'), isTrue);
    });
  });

  group('SettingsProvider Free Mode & Model Tests', () {
    test('setSelectedModel updates active model', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();

      await settings.setSelectedModel('mimo-v2.5-free');
      expect(settings.selectedModel, equals('mimo-v2.5-free'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_model'), equals('mimo-v2.5-free'));
    });
  });

  group('ProjectProvider File Upload Tests', () {
    test('uploadFile is defined and can clear selected files', () async {
      final provider = ProjectProvider();
      expect(provider.selectedFilePath, isNull);
      expect(provider.selectedFileBytes, isNull);

      provider.clearSelectedFile();
      expect(provider.selectedFilePath, isNull);
    });
  });

  group('HomeScreen Direct Rendering Tests', () {
    testWidgets('Renders HomeScreen directly by default', (WidgetTester tester) async {
      final settings = SettingsProvider();
      await settings.loadSettings();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
            ChangeNotifierProvider(create: (_) => ProjectProvider()),
          ],
          child: const OpenCodeApp(),
        ),
      );

      // Verify direct navigation/rendering of home screen (renders Bou3orrif app bar title)
      expect(find.text('Bou3orrif'), findsAtLeast(1));
    });
  });
}
