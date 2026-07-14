import 'dart:typed_data';

enum MessageRole { user, model }

class ChatMessage {
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  final String? attachedFileName;
  final String? attachedFileContent;
  final Uint8List? attachedFileBytes;
  final String? attachedFileMimeType;

  ChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.attachedFileName,
    this.attachedFileContent,
    this.attachedFileBytes,
    this.attachedFileMimeType,
  }) : timestamp = timestamp ?? DateTime.now();
}
