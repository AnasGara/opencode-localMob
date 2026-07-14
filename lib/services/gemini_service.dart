import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GenerativeModel? _model;
  bool _isFreeMode = false;

  bool get isInitialized => _model != null || _isFreeMode;

  void initialize(String apiKey) {
    if (apiKey == 'free') {
      _isFreeMode = true;
      _model = null;
      return;
    }
    _isFreeMode = false;
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'text/plain',
      ),
      systemInstruction: Content.system(
        "You are OpenCode, an expert AI programming assistant running inside a Flutter mobile app. "
        "Your task is to help the user write, debug, explain, and optimize code. "
        "The user can browse their local files and attach them to the chat context. "
        "Keep explanations clear and focused on working code. "
        "Always use proper Markdown formatting, and wrap code blocks in appropriate language tags (e.g. ```dart, ```yaml, etc.)."
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
      return "Hello! I am OpenCode, your AI programming assistant running on a free, lightweight local offline model. "
             "How can I help you with your coding, debugging, or project architecture tasks today?";
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
             "When designing clean, maintainable code, consider the following principles:\n"
             "- **Single Responsibility**: Every class and function should do exactly one thing well.\n"
             "- **Declarative UI**: In Flutter, state determines your UI (`UI = f(state)`). Avoid direct state mutations.\n"
             "- **Composition over Inheritance**: Build complex widgets and classes using smaller, reusable blocks.\n\n"
             "If you have a specific file or snippet you would like me to explain, select it from your file browser and let me know!";
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
             "      _data = \"Hello from the Free Offline Model!\";\n"
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
    return "Thank you for reaching out! I am OpenCode, running in **Free Offline Mode** (no Gemini API key required).\n\n"
           "I can help you build, explain, and debug applications right from your mobile device. "
           "You can also attach any local files from your workspace using the folder/browser tab.\n\n"
           "Feel free to ask specific coding questions or paste your scripts here!";
  }
}
