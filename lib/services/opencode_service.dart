import 'dart:io';
import 'dart:convert';

class OpenCodeService {
  String _modelName = 'big-pickle';
  String? _openaiApiKey;

  bool get isInitialized => true;

  void initialize({
    String? modelName,
    String? openaiApiKey,
  }) {
    _modelName = modelName ?? 'big-pickle';
    _openaiApiKey = openaiApiKey;
  }

  static Future<bool> validateConnection() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final url = Uri.parse('https://opencode.ai/zen/v1/chat/completions');
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType('application', 'json', charset: 'utf-8');

      final payload = {
        'model': 'big-pickle',
        'messages': [
          {'role': 'user', 'content': 'Validate'}
        ],
        'stream': false
      };

      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      client.close();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Stream<String> sendMessageStream(List<Map<String, dynamic>> messages) async* {
    final List<String> freeModels = [
      'big-pickle',
      'deepseek-v4-flash-free',
      'mimo-v2.5-free',
      'hy3-free',
      'nemotron-3-ultra-free',
      'north-mini-code-free',
    ];

    final isFreeModel = freeModels.contains(_modelName);
    final url = isFreeModel
        ? 'https://opencode.ai/zen/v1/chat/completions'
        : 'https://api.openai.com/v1/chat/completions';

    final headers = {
      'content-type': 'application/json; charset=utf-8',
    };

    if (!isFreeModel && _openaiApiKey != null && _openaiApiKey!.isNotEmpty) {
      headers['authorization'] = 'Bearer $_openaiApiKey';
    }

    final systemPrompt = "You are Bou3orrif, a polyvalent, intelligent AI assistant running inside a Flutter mobile app. "
        "Your task is to help the user with any tasks they have, including general knowledge questions, writing, debugging, explaining, and optimizing code. "
        "The user can browse their local files and attach them to the chat context. "
        "Keep explanations clear, engaging, and precise. "
        "Always use proper Markdown formatting, and wrap code blocks in appropriate language tags if outputting code.";

    final List<Map<String, dynamic>> apiMessages = [];
    apiMessages.add({
      'role': 'system',
      'content': systemPrompt,
    });
    apiMessages.addAll(messages);

    final body = {
      'model': _modelName,
      'messages': apiMessages,
      'stream': true,
    };

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    final request = await client.postUrl(Uri.parse(url));
    headers.forEach((k, v) => request.headers.set(k, v));

    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close();

    if (response.statusCode == 200) {
      final stream = response.transform(utf8.decoder).transform(const LineSplitter());
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
                  yield textChunk;
                }
              }
            }
          } catch (_) {
            // Non-blocking JSON decoding errors or meta-lines
          }
        }
      }
      client.close();
    } else {
      client.close();
      throw HttpException('Request failed with status code: ${response.statusCode}');
    }
  }
}
