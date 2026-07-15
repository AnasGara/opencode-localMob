import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import 'file_viewer_screen.dart';

class FileBrowserScreen extends StatelessWidget {
  const FileBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final filename = projectProvider.selectedFilePath?.split(Platform.pathSeparator).last;

    return Scaffold(
      body: projectProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload_rounded, size: 80, color: Colors.deepPurple),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload Media or Documents',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select a photo, video, or document file from your device to analyze with Bou3orrif.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                      ),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Select File'),
                      onPressed: projectProvider.uploadFile,
                    ),
                    if (projectProvider.selectedFilePath != null) ...[
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Currently Attached File:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        color: Colors.deepPurple.withValues(alpha: 0.05),
                        child: ListTile(
                          leading: Icon(
                            projectProvider.selectedFileBytes != null
                                ? (projectProvider.selectedFileMimeType?.startsWith('image/') == true
                                    ? Icons.image_rounded
                                    : Icons.video_camera_back_rounded)
                                : Icons.insert_drive_file_rounded,
                            color: Colors.deepPurple,
                          ),
                          title: Text(filename ?? ''),
                          subtitle: Text(projectProvider.selectedFileMimeType ?? 'Unknown Mime Type'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye_rounded, color: Colors.deepPurple),
                                tooltip: 'View File Content',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const FileViewerScreen()),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.red),
                                tooltip: 'Remove File',
                                onPressed: () {
                                  projectProvider.clearSelectedFile();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
