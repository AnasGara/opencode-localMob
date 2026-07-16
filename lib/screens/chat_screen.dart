import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_provider.dart';
import '../providers/project_provider.dart';
import '../models/chat_message.dart';
import '../services/file_service.dart';
import 'dart:io';
import '../providers/settings_provider.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

    if (text.isEmpty && projectProvider.selectedFilePath == null) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (projectProvider.selectedFilePath != null) {
      final filename = FileService.getFileName(projectProvider.selectedFilePath);
      chatProvider.sendMessage(
        text: text,
        attachedFileName: filename,
        attachedFileContent: projectProvider.selectedFileContent,
        attachedFileBytes: projectProvider.selectedFileBytes,
        attachedFileMimeType: projectProvider.selectedFileMimeType,
      );
      projectProvider.clearSelectedFile();
    } else {
      chatProvider.sendMessage(text: text);
    }

    _inputController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);

    if (chatProvider.streamingText.isNotEmpty || chatProvider.isLoading) {
      _scrollToBottom();
    }

    return Column(
      children: [
        Expanded(
          child: chatProvider.messages.isEmpty && chatProvider.streamingText.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // A beautifully animated, custom-drawn Genie Lamp & Smoke
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(180, 180),
                              painter: GeniePainter(animationValue: _animationController.value),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chobbik lobbik\nBou3orrif bin ydik',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your powerful AI Genie is ready to assist you!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: chatProvider.messages.length + (chatProvider.streamingText.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chatProvider.messages.length) {
                      return _buildMessageBubble(
                        ChatMessage(
                          role: MessageRole.model,
                          text: chatProvider.streamingText,
                        ),
                      );
                    }
                    return _buildMessageBubble(chatProvider.messages[index]);
                  },
                ),
        ),
        if (projectProvider.selectedFilePath != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.deepPurple.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.attach_file_rounded, size: 20, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Referencing: ${FileService.getFileName(projectProvider.selectedFilePath)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  tooltip: 'Remove Attachment',
                  onPressed: () {
                    projectProvider.clearSelectedFile();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.deepPurple),
                  tooltip: 'Inject context & prompt',
                  onPressed: () {
                    final filename = FileService.getFileName(projectProvider.selectedFilePath);
                    if (projectProvider.selectedFileBytes != null) {
                      chatProvider.sendMessage(
                        text: "Analyze this file and tell me what you see or what it represents.",
                        attachedFileName: filename,
                        attachedFileBytes: projectProvider.selectedFileBytes,
                        attachedFileMimeType: projectProvider.selectedFileMimeType,
                      );
                      projectProvider.clearSelectedFile();
                    } else if (projectProvider.selectedFileContent != null) {
                      chatProvider.sendMessage(
                        text: "Analyze this file. What does it do and are there any bugs?",
                        attachedFileName: filename,
                        attachedFileContent: projectProvider.selectedFileContent,
                      );
                      projectProvider.clearSelectedFile();
                    }
                    _scrollToBottom();
                  },
                )
              ],
            ),
          ),
        SafeArea(
          top: false,
          child: _buildInputBar(chatProvider),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == MessageRole.user;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isUser ? Colors.deepPurple : Theme.of(context).cardColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Icon(isUser ? Icons.person_rounded : Icons.auto_awesome_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(isUser ? 'You' : 'Bou3orrif', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                bottomRight: isUser ? Radius.zero : const Radius.circular(12),
              ),
            ),
            child: isUser
                ? Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 15))
                : MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      code: const TextStyle(fontFamily: 'monospace', backgroundColor: Colors.transparent),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndSendPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (!mounted) return;
        final name = photo.name;
        final mimeType = photo.mimeType ?? 'image/jpeg';

        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        await chatProvider.sendMessage(
          text: "",
          attachedFileName: name,
          attachedFileBytes: bytes,
          attachedFileMimeType: mimeType,
        );
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error in _captureAndSendPhoto: $e');
    }
  }

  Future<void> _pickAndSendPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        final name = image.name;
        final extension = name.split('.').last.toLowerCase();
        String mimeType = image.mimeType ?? 'image/jpeg';
        if (image.mimeType == null) {
          switch (extension) {
            case 'png': mimeType = 'image/png'; break;
            case 'jpg':
            case 'jpeg': mimeType = 'image/jpeg'; break;
            case 'webp': mimeType = 'image/webp'; break;
            case 'gif': mimeType = 'image/gif'; break;
          }
        }

        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        await chatProvider.sendMessage(
          text: "",
          attachedFileName: name,
          attachedFileBytes: bytes,
          attachedFileMimeType: mimeType,
        );
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error in _pickAndSendPhoto: $e');
    }
  }

  String? _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'webp': return 'image/webp';
      case 'gif': return 'image/gif';
      case 'mp4': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case 'webm': return 'video/webm';
      case 'avi': return 'video/x-msvideo';
      case 'pdf': return 'application/pdf';
      case 'txt': return 'text/plain';
      case 'dart': return 'text/x-dart';
      case 'yaml': return 'text/x-yaml';
      case 'json': return 'application/json';
      default: return null;
    }
  }

  bool _isBinaryFile(String filePath) {
    final mime = _getMimeType(filePath);
    if (mime == null) return false;
    return mime.startsWith('image/') || mime.startsWith('video/') || mime == 'application/pdf';
  }

  Future<void> _pickAndSendFile() async {
    try {
      final fileService = FileService();
      final result = await fileService.pickFile();
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          final filePath = file.path!;
          final fileName = FileService.getFileName(filePath);

          final isBinary = _isBinaryFile(filePath);
          if (isBinary) {
            final ioFile = File(filePath);
            final bytes = await ioFile.readAsBytes();
            if (!mounted) return;
            final mimeType = _getMimeType(filePath) ?? 'application/octet-stream';

            final chatProvider = Provider.of<ChatProvider>(context, listen: false);
            await chatProvider.sendMessage(
              text: "",
              attachedFileName: fileName,
              attachedFileBytes: bytes,
              attachedFileMimeType: mimeType,
            );
          } else {
            final ioFile = File(filePath);
            final content = await ioFile.readAsString();
            if (!mounted) return;

            final chatProvider = Provider.of<ChatProvider>(context, listen: false);
            await chatProvider.sendMessage(
              text: "",
              attachedFileName: fileName,
              attachedFileContent: content,
            );
          }
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error in _pickAndSendFile: $e');
    }
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.deepPurple),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _captureAndSendPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.deepPurple),
                title: const Text('Upload Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndSendPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.deepPurple),
                title: const Text('Upload File'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndSendFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar(ChatProvider chatProvider) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isAttachmentSupported = settingsProvider.selectedModel == 'big-pickle';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          if (isAttachmentSupported)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.deepPurple),
              tooltip: 'Upload image/video/doc/photo',
              onPressed: () => _showAttachmentOptions(context),
            ),
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                hintText: 'Ask Bou3orrif anything...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          chatProvider.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.deepPurple),
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }
}

class GeniePainter extends CustomPainter {
  final double animationValue;

  GeniePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Magical Smoke
    final smokePaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw some dynamic swirling smoke clouds from the spout location
    // Spout is roughly at (center.dx - 40, center.dy)
    final spoutX = center.dx - 40;
    final spoutY = center.dy - 10;

    for (int i = 0; i < 4; i++) {
      final progress = (animationValue + i / 4) % 1.0;
      final radius = 10.0 + progress * 25.0;
      final dx = spoutX - progress * 50.0 + (progress * 20.0 * (i % 2 == 0 ? 1 : -1));
      final dy = spoutY - progress * 70.0;

      canvas.drawCircle(Offset(dx, dy), radius, smokePaint);
    }

    // 2. Base/Shadow
    paint.color = Colors.black26;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 45), width: 100, height: 15),
      paint,
    );

    // 3. Gold Genie Lamp body
    final lampColor = Colors.amber;
    paint.color = lampColor;
    paint.style = PaintingStyle.fill;

    // Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + 5, center.dy + 35), width: 60, height: 12),
        const Radius.circular(6),
      ),
      paint,
    );

    // Stand
    final standPath = Path()
      ..moveTo(center.dx - 15, center.dy + 35)
      ..lineTo(center.dx + 25, center.dy + 35)
      ..lineTo(center.dx + 15, center.dy + 15)
      ..lineTo(center.dx - 5, center.dy + 15)
      ..close();
    canvas.drawPath(standPath, paint);

    // Main Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + 10, center.dy + 10), width: 90, height: 50),
      paint,
    );

    // Handle
    final handlePaint = Paint()
      ..color = lampColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx + 45, center.dy + 5), width: 35, height: 45),
      -1.2,
      2.4,
      false,
      handlePaint,
    );

    // Spout (Nozzle)
    final spoutPath = Path()
      ..moveTo(center.dx - 30, center.dy + 15)
      ..quadraticBezierTo(center.dx - 50, center.dy - 10, center.dx - 65, center.dy - 5)
      ..lineTo(center.dx - 65, center.dy + 5)
      ..quadraticBezierTo(center.dx - 45, center.dy + 15, center.dx - 30, center.dy + 25)
      ..close();
    canvas.drawPath(spoutPath, paint);

    // Lid and Knob
    paint.style = PaintingStyle.fill;
    paint.color = Colors.amber.shade700;
    canvas.drawCircle(Offset(center.dx + 10, center.dy - 18), 7, paint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + 10, center.dy - 13), width: 35, height: 8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant GeniePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
