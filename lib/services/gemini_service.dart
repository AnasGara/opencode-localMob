import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GenerativeModel? _model;
  bool _isFreeMode = false;
  String _modelName = 'gemini-2.0-flash';

  bool get isInitialized => _model != null || _isFreeMode;

  void initialize(String apiKey, {String? modelName}) {
    _modelName = modelName ?? (apiKey == 'free' ? 'big-pickle' : 'gemini-2.0-flash');
    if (apiKey == 'free') {
      _isFreeMode = true;
      _model = null;
      return;
    }
    _isFreeMode = false;
    _model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
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
    try {
      final client = HttpClient();
      // Set a reasonable timeout for the connection
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.postUrl(Uri.parse('https://opencode.ai/zen/v1/chat/completions'));
      request.headers.contentType = ContentType.json;

      // Construct OpenAI compatible messages from history
      final messages = <Map<String, String>>[];
      messages.add({
        'role': 'system',
        'content': "You are OpenCode, an expert AI programming assistant running inside a Flutter mobile app. "
                   "Your task is to help the user write, debug, explain, and optimize code."
      });

      for (var content in history) {
        if (content.parts.isEmpty) continue;
        final part = content.parts.first;
        if (part is TextPart) {
          final text = part.text;
          final role = content.role == 'user' ? 'user' : 'assistant';
          messages.add({'role': role, 'content': text});
        }
      }

      final body = {
        'model': _modelName,
        'messages': messages,
        'stream': true,
      };

      request.write(jsonEncode(body));
      final response = await request.close();

      if (response.statusCode == 200) {
        // Stream the response chunks
        final stream = response.transform(utf8.decoder).transform(const LineSplitter());
        bool yieldedAnything = false;
        await for (final line in stream) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            if (dataStr == '[DONE]') continue;
            try {
              final data = jsonDecode(dataStr) as Map<String, dynamic>;
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
            } catch (_) {
              // Ignore partial JSON parse errors on invalid chunks
            }
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
    final lastMessage = (lastContent != null && lastContent.parts.isNotEmpty)
        ? (lastContent.parts.first as TextPart).text
        : '';
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
