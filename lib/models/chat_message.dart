class ChatMessage {
  final MessageRole role;
  final String text;
  final String? attachedFileName;
  final String? attachedFileContent;
  final List<int>? attachedFileBytes;
  final String? attachedFileMimeType;

  ChatMessage({
    required this.role,
    required this.text,
    this.attachedFileName,
    this.attachedFileContent,
    this.attachedFileBytes,
    this.attachedFileMimeType,
  });
}

enum MessageRole {
  user,
  model,
}
