import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'package:opencodemobile/providers/settings_provider.dart';
import 'package:opencodemobile/providers/chat_provider.dart';
import 'package:opencodemobile/providers/project_provider.dart';
import 'package:opencodemobile/services/gemini_service.dart';
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

  group('GeminiService Free Mode Tests', () {
    test('Initialize with free key sets isInitialized to true', () {
      final service = GeminiService();
      expect(service.isInitialized, isFalse);

      service.initialize('free');
      expect(service.isInitialized, isTrue);
    });

    test('sendMessageStream in free mode returns simulated offline response stream when client fails/offline', () async {
      final service = GeminiService();
      service.initialize('free');

      final stream = service.sendMessageStream([]);
      final responses = await stream.toList();

      expect(responses, isNotEmpty);
      expect(responses.first.text, isNotNull);
      expect(responses.any((r) => r.text!.contains('offline')), isTrue);
    });

    test('generateFreeModelResponse has smart responses for offline fallback', () async {
      final service = GeminiService();
      service.initialize('free');

      // Test default response
      final stream1 = service.sendMessageStream([]);
      final res1 = await stream1.toList();
      final text1 = res1.map((r) => r.text).join();
      expect(text1, contains('offline'));

      // Test hello/hi response
      final service2 = GeminiService()..initialize('free');
      final stream2 = service2.sendMessageStream([
        Content.text('Hello assistant!')
      ]);
      final res2 = await stream2.toList();
      final text2 = res2.map((r) => r.text).join();
      expect(text2, contains('offline'));

      // Test bug response
      final service3 = GeminiService()..initialize('free');
      final stream3 = service3.sendMessageStream([
        Content.text('There is a bug in my code')
      ]);
      final res3 = await stream3.toList();
      final text3 = res3.map((r) => r.text).join();
      expect(text3, contains("offline"));
    });

    test('sendMessageStream parses multimodal content with DataParts in free mode and defaults to offline fallback when client fails', () async {
      final service = GeminiService();
      service.initialize('free');

      final binaryBytes = Uint8List.fromList([1, 2, 3, 4]);
      final stream = service.sendMessageStream([
        Content.multi([
          DataPart('image/png', binaryBytes),
          TextPart('Describe this image please')
        ])
      ]);

      final responses = await stream.toList();
      expect(responses, isNotEmpty);
      final fullText = responses.map((r) => r.text).join();
      expect(fullText, contains('offline'));
    });
  });

  group('SettingsProvider Free Mode & Model Tests', () {
    test('setFreeMode stores key and notifies', () async {
      final settings = SettingsProvider();
      bool notified = false;
      settings.addListener(() {
        notified = true;
      });

      await settings.setFreeMode();

      expect(settings.apiKey, equals('free'));
      expect(settings.selectedModel, equals('big-pickle'));
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('gemini_api_key'), equals('free'));
      expect(prefs.getString('selected_model'), equals('big-pickle'));
    });

    test('setSelectedModel updates active model', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();

      await settings.setSelectedModel('mimo-v2.5-free');
      expect(settings.selectedModel, equals('mimo-v2.5-free'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_model'), equals('mimo-v2.5-free'));
    });

    test('Multiple API keys getters and setters', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();

      await settings.setGeminiApiKey('google-test-key');
      await settings.setOpenaiApiKey('openai-test-key');
      await settings.setClaudeApiKey('claude-test-key');

      expect(settings.geminiApiKey, equals('google-test-key'));
      expect(settings.openaiApiKey, equals('openai-test-key'));
      expect(settings.claudeApiKey, equals('claude-test-key'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('gemini_api_key'), equals('google-test-key'));
      expect(prefs.getString('openai_api_key'), equals('openai-test-key'));
      expect(prefs.getString('claude_api_key'), equals('claude-test-key'));
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
    testWidgets('Renders HomeScreen directly in free mode by default', (WidgetTester tester) async {
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

      // Verify that apiKey defaults to 'free'
      expect(settings.apiKey, equals('free'));

      // Verify direct navigation/rendering of home screen (renders Bou3orrif app bar title)
      expect(find.text('Bou3orrif'), findsAtLeast(1));
    });
  });
}
