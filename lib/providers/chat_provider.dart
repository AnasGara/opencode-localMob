import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';

class ChatProvider with ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
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
    _geminiService.initialize(
      apiKey,
      modelName: modelName,
      openaiApiKey: openaiApiKey,
      claudeApiKey: claudeApiKey,
      geminiApiKey: geminiApiKey,
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
      final List<Content> apiHistory = [];

      for (var msg in _messages) {
        String contentText = msg.text;
        if (msg.attachedFileName != null && msg.attachedFileContent != null) {
          contentText = "[Attached Code File: ${msg.attachedFileName}]\n"
              "```\n${msg.attachedFileContent}\n```\n\n"
              "$contentText";
        }

        if (msg.role == MessageRole.user) {
          if (msg.attachedFileBytes != null && msg.attachedFileMimeType != null) {
            apiHistory.add(Content.multi([
              DataPart(msg.attachedFileMimeType!, msg.attachedFileBytes!),
              TextPart(contentText.isEmpty ? "Analyze this file" : contentText),
            ]));
          } else {
            apiHistory.add(Content.text(contentText));
          }
        } else {
          apiHistory.add(Content.model([TextPart(msg.text)]));
        }
      }

      final responseStream = _geminiService.sendMessageStream(apiHistory);
      _isLoading = false; 
      notifyListeners();

      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          _streamingText += chunk.text!;
          notifyListeners();
        }
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
