import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../services/file_service.dart';

class FileViewerScreen extends StatelessWidget {
  const FileViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final filename = projectProvider.selectedFilePath != null
        ? FileService.getFileName(projectProvider.selectedFilePath)
        : 'Viewer';

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
          : projectProvider.selectedFileBytes != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (projectProvider.selectedFileMimeType?.startsWith('image/') == true) ...[
                          Expanded(
                            child: InteractiveViewer(
                              child: Image.memory(projectProvider.selectedFileBytes!),
                            ),
                          ),
                        ] else if (projectProvider.selectedFileMimeType?.startsWith('video/') == true) ...[
                          const Icon(Icons.video_camera_back_rounded, size: 80, color: Colors.deepPurple),
                          const SizedBox(height: 16),
                          Text(
                            'Video File Selected: $filename',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bou3orrif can analyze and discuss this video in chat!',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          const Icon(Icons.insert_drive_file_rounded, size: 80, color: Colors.deepPurple),
                          const SizedBox(height: 16),
                          Text(
                            'Document File Selected: $filename',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                )
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
