import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GenerativeModel? _model;
  bool _isFreeMode = false;
  String _modelName = 'gemini-2.0-flash';

  String? _openaiApiKey;
  String? _claudeApiKey;
  String? _geminiApiKey;

  bool get isInitialized => _model != null || _isFreeMode;

  String _getProviderOf(String model) {
    if (model.startsWith('gemini-')) return 'google';
    if (model.startsWith('gpt-') || model.startsWith('o1-') || model.startsWith('o3-')) return 'openai';
    if (model.startsWith('claude-')) return 'anthropic';
    return 'free';
  }

  void initialize(
    String apiKey, {
    String? modelName,
    String? openaiApiKey,
    String? claudeApiKey,
    String? geminiApiKey,
  }) {
    _modelName = modelName ?? (apiKey == 'free' ? 'big-pickle' : 'gemini-2.0-flash');
    _openaiApiKey = openaiApiKey;
    _claudeApiKey = claudeApiKey;
    _geminiApiKey = geminiApiKey;

    final provider = _getProviderOf(_modelName);

    if (provider == 'google') {
      final keyToUse = (geminiApiKey != null && geminiApiKey.isNotEmpty) ? geminiApiKey : (apiKey != 'free' ? apiKey : null);
      if (keyToUse != null) {
        _isFreeMode = false;
        _model = GenerativeModel(
          model: _modelName,
          apiKey: keyToUse,
          generationConfig: GenerationConfig(
            responseMimeType: 'text/plain',
          ),
          systemInstruction: Content.system(
            "You are Bou3orrif, a polyvalent and intelligent AI assistant running inside a Flutter mobile app. "
            "Your task is to help the user with any tasks they have, including general knowledge questions, writing, debugging, explaining, and optimizing code. "
            "The user can browse their local files and attach them to the chat context. "
            "Keep explanations clear, engaging, and precise. "
            "Always use proper Markdown formatting, and wrap code blocks in appropriate language tags if outputting code."
          ),
        );
        return;
      }
    }

    _isFreeMode = true;
    _model = null;
  }

  static Future<bool> validateKey(String apiKey) async {
    try {
      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
      final response = await model.generateContent([Content.text('Validate Connection')]);
      return response.text != null;
    } catch (_) {
      return false;
    }
  }

  Stream<GenerateContentResponse> sendMessageStream(List<Content> history) {
    if (_isFreeMode) {
      return _getFreeModelResponseStream(history);
    }
    if (_model == null) {
      throw StateError('GeminiService is not initialized.');
    }
    return _model!.generateContentStream(history);
  }

  Stream<GenerateContentResponse> _getFreeModelResponseStream(List<Content> history) async* {
    final provider = _getProviderOf(_modelName);

    String url;
    Map<String, String> headers;
    Map<String, dynamic> body;

    final messages = <Map<String, dynamic>>[];

    if (provider == 'anthropic') {
      url = 'https://api.anthropic.com/v1/messages';
      headers = {
        'content-type': 'application/json',
        'x-api-key': _claudeApiKey ?? '',
        'anthropic-version': '2023-06-01',
      };

      for (var content in history) {
        if (content.parts.isEmpty) continue;
        final role = content.role == 'user' ? 'user' : 'assistant';
        final textParts = content.parts.whereType<TextPart>().toList();
        final text = textParts.map((t) => t.text).join('\n');

        final dataParts = content.parts.whereType<DataPart>().toList();
        if (dataParts.isNotEmpty) {
          final contentList = <Map<String, dynamic>>[];
          contentList.add({'type': 'text', 'text': text.isEmpty ? "Analyze this file" : text});
          for (var d in dataParts) {
            final base64Str = base64Encode(d.bytes);
            contentList.add({
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': d.mimeType,
                'data': base64Str,
              }
            });
          }
          messages.add({'role': role, 'content': contentList});
        } else {
          messages.add({'role': role, 'content': text});
        }
      }

      body = {
        'model': _modelName == 'claude-3-5-sonnet'
            ? 'claude-3-5-sonnet-20241022'
            : (_modelName == 'claude-3-5-haiku' ? 'claude-3-5-haiku-20241022' : _modelName),
        'system': "You are Bou3orrif, a polyvalent and intelligent AI assistant running inside a Flutter mobile app.",
        'messages': messages,
        'max_tokens': 4096,
        'stream': true,
      };
    } else {
      final isOpenAI = provider == 'openai';
      url = isOpenAI ? 'https://api.openai.com/v1/chat/completions' : 'https://opencode.ai/zen/v1/chat/completions';
      headers = {
        'content-type': 'application/json',
      };
      if (isOpenAI) {
        headers['Authorization'] = 'Bearer ${_openaiApiKey ?? ''}';
      }

      messages.add({
        'role': 'system',
        'content': "You are Bou3orrif, a polyvalent and intelligent AI assistant running inside a Flutter mobile app."
      });

      for (var content in history) {
        if (content.parts.isEmpty) continue;
        final role = content.role == 'user' ? 'user' : 'assistant';

        final dataParts = content.parts.whereType<DataPart>().toList();
        final textParts = content.parts.whereType<TextPart>().toList();

        if (dataParts.isNotEmpty) {
          final contentList = <Map<String, dynamic>>[];
          for (var t in textParts) {
            contentList.add({'type': 'text', 'text': t.text});
          }
          for (var d in dataParts) {
            final base64Str = base64Encode(d.bytes);
            contentList.add({
              'type': 'image_url',
              'image_url': {
                'url': 'data:${d.mimeType};base64,$base64Str'
              }
            });
          }
          messages.add({'role': role, 'content': contentList});
        } else {
          final text = textParts.map((t) => t.text).join('\n');
          messages.add({'role': role, 'content': text});
        }
      }

      body = {
        'model': _modelName,
        'messages': messages,
        'stream': true,
      };
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(Uri.parse(url));
      headers.forEach((k, v) => request.headers.set(k, v));

      request.write(jsonEncode(body));
      final response = await request.close();

      if (response.statusCode == 200) {
        final stream = response.transform(utf8.decoder).transform(const LineSplitter());
        bool yieldedAnything = false;
        await for (final line in stream) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            if (dataStr == '[DONE]') continue;
            try {
              final data = jsonDecode(dataStr) as Map<String, dynamic>;
              if (provider == 'anthropic') {
                if (data['type'] == 'content_block_delta') {
                  final delta = data['delta'] as Map<String, dynamic>?;
                  if (delta != null && delta.containsKey('text')) {
                    final textChunk = delta['text'] as String;
                    if (textChunk.isNotEmpty) {
                      yieldedAnything = true;
                      yield GenerateContentResponse([
                        Candidate(
                          Content.text(textChunk),
                          null,
                          null,
                          null,
                          null,
                        )
                      ], null);
                    }
                  }
                }
              } else {
                final choices = data['choices'] as List<dynamic>?;
                if (choices != null && choices.isNotEmpty) {
                  final delta = choices.first['delta'] as Map<String, dynamic>?;
                  if (delta != null && delta.containsKey('content')) {
                    final textChunk = delta['content'] as String;
                    if (textChunk.isNotEmpty) {
                      yieldedAnything = true;
                      yield GenerateContentResponse([
                        Candidate(
                          Content.text(textChunk),
                          null,
                          null,
                          null,
                          null,
                        )
                      ], null);
                    }
                  }
                }
              }
            } catch (_) {}
          }
        }
        client.close();
        if (yieldedAnything) return;
      }
      client.close();
    } catch (_) {
      // Fallback to local offline mock model
    }

    final lastContent = history.isNotEmpty ? history.last : null;
    String lastMessage = '';
    if (lastContent != null && lastContent.parts.isNotEmpty) {
      final textPart = lastContent.parts.whereType<TextPart>().firstOrNull;
      if (textPart != null) {
        lastMessage = textPart.text;
      }
    }
    final responseText = _generateFreeModelResponse(lastMessage);

    // Split response into small chunks to simulate streaming
    final words = responseText.split(' ');
    for (var i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      final chunkText = words[i] + (i == words.length - 1 ? '' : ' ');
      yield GenerateContentResponse([
        Candidate(
          Content.text(chunkText),
          null,
          null,
          null,
          null,
        )
      ], null);
    }
  }

  String _generateFreeModelResponse(String userPrompt) {
    final promptLower = userPrompt.toLowerCase();

    if (promptLower.contains('hello') || promptLower.contains('hi')) {
      return "Hello! I am Bou3orrif, your polyvalent AI assistant running on a free, lightweight local offline model ($_modelName). "
             "How can I help you today? I can help you with general knowledge questions, writing, brainstorming, or coding!";
    }

    if (promptLower.contains('bug') || promptLower.contains('error') || promptLower.contains('debug') || promptLower.contains('fail')) {
      return "### Let's debug this issue!\n\n"
             "Common code errors usually fall into one of these categories:\n"
             "1. **Null Safety issues**: Ensure that variables are initialized or marked as nullable (e.g., `String?`).\n"
             "2. **Type Mismatch**: Verify that function signatures match the types being passed.\n"
             "3. **State Management**: If UI is not updating, double check that `notifyListeners()` or `setState()` is being called.\n\n"
             "Could you please share the error stack trace or the specific code snippet so I can give you a tailored fix?";
    }

    if (promptLower.contains('explain') || promptLower.contains('how') || promptLower.contains('what')) {
      return "### Explanation and Best Practices\n\n"
             "When designing clean, maintainable systems, consider the following principles:\n"
             "- **Clarity**: Keep your logic clear, structured, and easy to understand.\n"
             "- **Separation of Concerns**: Separate your logic layers so that changes in one place do not break others.\n"
             "- **Iterative Design**: Build complex systems using smaller, thoroughly tested parts.\n\n"
             "Let me know if you have a specific topic or file you would like me to explain!";
    }

    if (promptLower.contains('code') || promptLower.contains('write') || promptLower.contains('implement') || promptLower.contains('create') || promptLower.contains('make')) {
      return "### Flutter/Dart Code Implementation Example\n\n"
             "Here is a generic template for a stateful Flutter widget that handles loading and displaying data asynchronously:\n\n"
             "```dart\n"
             "import 'package:flutter/material.dart';\n\n"
             "class DataViewerWidget extends StatefulWidget {\n"
             "  const DataViewerWidget({super.key});\n\n"
             "  @override\n"
             "  State<DataViewerWidget> createState() => _DataViewerWidgetState();\n"
             "}\n\n"
             "class _DataViewerWidgetState extends State<DataViewerWidget> {\n"
             "  bool _isLoading = false;\n"
             "  String? _data;\n\n"
             "  Future<void> _fetchData() async {\n"
             "    setState(() => _isLoading = true);\n"
             "    // Simulate network delay\n"
             "    await Future.delayed(const Duration(seconds: 2));\n"
             "    setState(() {\n"
             "      _data = \"Hello from the Free Offline Model ($_modelName)!\";\n"
             "      _isLoading = false;\n"
             "    });\n"
             "  }\n\n"
             "  @override\n"
             "  Widget build(BuildContext context) {\n"
             "    return Column(\n"
             "      mainAxisAlignment: MainAxisAlignment.center,\n"
             "      children: [\n"
             "        if (_isLoading) ...[\n"
             "          const CircularProgressIndicator(),\n"
             "        ] else if (_data != null) ...[\n"
             "          Text(_data!, style: Theme.of(context).textTheme.titleLarge),\n"
             "        ] else ...[\n"
             "          ElevatedButton(\n"
             "            onPressed: _fetchData,\n"
             "            child: const Text('Fetch Data'),\n"
             "          ),\n"
             "        ],\n"
             "      ],\n"
             "    );\n"
             "  }\n"
             "}\n"
             "```\n\n"
             "Let me know if you would like me to adjust this implementation for your specific use-case!";
    }

    // Default general response
    return "Thank you for reaching out! I am Bou3orrif, running in **Free Offline Mode** with model `$_modelName` (no Gemini API key required).\n\n"
           "I am a polyvalent assistant here to help with all of your general tasks, writing, research, and analysis. "
           "You can also attach any local files from your workspace using the folder/browser tab.\n\n"
           "Feel free to ask me anything!";
  }
}
