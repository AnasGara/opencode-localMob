enum MessageRole { user, model }

class ChatMessage {
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  final String? attachedFileName;
  final String? attachedFileContent;

  ChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.attachedFileName,
    this.attachedFileContent,
  }) : timestamp = timestamp ?? DateTime.now();
}
