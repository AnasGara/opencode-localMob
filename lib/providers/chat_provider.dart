import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/opencode_service.dart';

class ChatProvider with ChangeNotifier {
  final OpenCodeService _openCodeService = OpenCodeService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _streamingText = '';

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String get streamingText => _streamingText;

  void initialize(
    String apiKey, {
    String? modelName,
    String? openaiApiKey,
    String? claudeApiKey,
    String? geminiApiKey,
  }) {
    _openCodeService.initialize(
      modelName: modelName,
      openaiApiKey: openaiApiKey,
    );
  }

  Future<void> sendMessage({
    required String text,
    String? attachedFileName,
    String? attachedFileContent,
    Uint8List? attachedFileBytes,
    String? attachedFileMimeType,
  }) async {
    if (text.trim().isEmpty && attachedFileContent == null && attachedFileBytes == null) return;

    final userMessage = ChatMessage(
      role: MessageRole.user,
      text: text,
      attachedFileName: attachedFileName,
      attachedFileContent: attachedFileContent,
      attachedFileBytes: attachedFileBytes,
      attachedFileMimeType: attachedFileMimeType,
    );

    _messages.add(userMessage);
    _isLoading = true;
    _streamingText = '';
    notifyListeners();

    try {
      final List<Map<String, dynamic>> apiHistory = [];

      for (var msg in _messages) {
        String contentText = msg.text;
        if (msg.attachedFileName != null && msg.attachedFileContent != null) {
          contentText = "[Attached Code File: ${msg.attachedFileName}]\n"
              "```\n${msg.attachedFileContent}\n```\n\n"
              "$contentText";
        }

        if (msg.role == MessageRole.user) {
          if (msg.attachedFileBytes != null && msg.attachedFileMimeType != null) {
            final base64Str = base64Encode(msg.attachedFileBytes!);
            apiHistory.add({
              'role': 'user',
              'content': [
                {'type': 'text', 'text': contentText.isEmpty ? "Analyze this file" : contentText},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:${msg.attachedFileMimeType};base64,$base64Str'
                  }
                }
              ]
            });
          } else {
            apiHistory.add({
              'role': 'user',
              'content': contentText,
            });
          }
        } else {
          apiHistory.add({
            'role': 'assistant',
            'content': msg.text,
          });
        }
      }

      final responseStream = _openCodeService.sendMessageStream(apiHistory);
      _isLoading = false; 
      notifyListeners();

      await for (final chunk in responseStream) {
        _streamingText += chunk;
        notifyListeners();
      }

      _messages.add(ChatMessage(
        role: MessageRole.model,
        text: _streamingText,
      ));
      _streamingText = '';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _streamingText = '';
      _messages.add(ChatMessage(
        role: MessageRole.model,
        text: "Connection failed: $e",
      ));
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    _streamingText = '';
    _isLoading = false;
    notifyListeners();
  }
}
