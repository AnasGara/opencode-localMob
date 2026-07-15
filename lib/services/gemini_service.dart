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

    bool yieldedAnything = false;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(Uri.parse(url));
      headers.forEach((k, v) => request.headers.set(k, v));

      request.write(jsonEncode(body));
      final response = await request.close();

      if (response.statusCode == 200) {
        final stream = response.transform(utf8.decoder).transform(const LineSplitter());
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
      } else {
        client.close();
        throw HttpException('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback or bubble up offline status
      if (!yieldedAnything) {
        final offlineResponse = "Connection failed: The app is offline. Please check your network connection.";
        // Split response into small chunks to simulate streaming
        final words = offlineResponse.split(' ');
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
        return;
      }
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

    if (promptLower.isEmpty) {
      return "Connection failed: The app is offline. Please check your network connection.";
    }

    if (promptLower.contains('hello') || promptLower.contains('hi')) {
      return "Hello! I am Bou3orrif, your polyvalent AI assistant. It looks like we are offline right now. "
             "Once you are reconnected, you can chat with free models like $_modelName!";
    }

    if (promptLower.contains('bug') || promptLower.contains('error') || promptLower.contains('debug') || promptLower.contains('fail')) {
      return "Connection failed: The app is offline. Please check your network connection to help debug this issue with $_modelName.";
    }

    if (promptLower.contains('explain') || promptLower.contains('how') || promptLower.contains('what')) {
      return "Connection failed: The app is offline. Please check your network connection to explain or answer your questions.";
    }

    if (promptLower.contains('code') || promptLower.contains('write') || promptLower.contains('implement') || promptLower.contains('create') || promptLower.contains('make')) {
      return "Connection failed: The app is offline. Please check your network connection to generate or run code implementations.";
    }

    // Default offline/general response
    return "Connection failed: The app is offline. Please check your network connection.";
  }
}
