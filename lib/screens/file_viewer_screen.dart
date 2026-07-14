import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';

class FileViewerScreen extends StatelessWidget {
  const FileViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final filename = projectProvider.selectedFilePath?.split(Platform.pathSeparator).last ?? 'Viewer';

    return Scaffold(
      appBar: AppBar(
        title: Text(filename),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded),
            tooltip: 'Reference in Chat',
            onPressed: () => Navigator.pop(context), 
          ),
        ],
      ),
      body: projectProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : projectProvider.selectedFileContent == null
              ? const Center(child: Text('Failed to read content.'))
              : Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0xFF1E1E1E), // editor dark bg
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        projectProvider.selectedFileContent!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFFD4D4D4), // syntax editor theme text
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
