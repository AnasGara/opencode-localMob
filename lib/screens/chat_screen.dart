import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_provider.dart';
import '../providers/project_provider.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

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
    if (text.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(text: text);
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
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.terminal_rounded, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'OpenCode AI Sandbox',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Open the "Files" tab to import/reference a workspace!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
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
            color: Colors.deepPurple.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.attach_file_rounded, size: 20, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Referencing: ${projectProvider.selectedFilePath!.split(Platform.pathSeparator).last}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.deepPurple),
                  tooltip: 'Inject context & prompt',
                  onPressed: () {
                    if (projectProvider.selectedFileContent != null) {
                      final filename = projectProvider.selectedFilePath!.split(Platform.pathSeparator).last;
                      chatProvider.sendMessage(
                        text: "Analyze this file. What does it do and are there any bugs?",
                        attachedFileName: filename,
                        attachedFileContent: projectProvider.selectedFileContent,
                      );
                      _scrollToBottom();
                    }
                  },
                )
              ],
            ),
          ),
        _buildInputBar(chatProvider),
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
              Icon(isUser ? Icons.person_rounded : Icons.android_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(isUser ? 'You' : 'OpenCode', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                        color: Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                hintText: 'Ask a coding question...',
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
