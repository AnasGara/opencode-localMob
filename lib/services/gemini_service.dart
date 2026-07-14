import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GenerativeModel? _model;

  bool get isInitialized => _model != null;

  void initialize(String apiKey) {
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
    if (_model == null) {
      throw StateError('GeminiService is not initialized.');
    }
    return _model!.generateContentStream(history);
  }
}
