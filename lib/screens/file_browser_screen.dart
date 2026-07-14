import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/file_node.dart';
import 'file_viewer_screen.dart';

class FileBrowserScreen extends StatelessWidget {
  const FileBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      body: projectProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : projectProvider.rootNode == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open_rounded, size: 70, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Workspace Closed',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text('Open a directory to index its codebase.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Open Project Folder'),
                        onPressed: projectProvider.openProject,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.deepPurple.withValues(alpha: 0.05),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_shared_rounded, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              projectProvider.projectPath ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.red),
                            onPressed: projectProvider.closeProject,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          _buildNodeWidget(context, projectProvider.rootNode!, projectProvider),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNodeWidget(BuildContext context, FileNode node, ProjectProvider provider) {
    if (node.isDirectory) {
      return ExpansionTile(
        key: PageStorageKey<String>(node.path),
        title: Text(node.name),
        leading: const Icon(Icons.folder_rounded, color: Colors.amber),
        initiallyExpanded: node.isExpanded,
        onExpansionChanged: (expanded) {
          provider.loadNodeChildren(node);
        },
        children: node.children.map((child) => _buildNodeWidget(context, child, provider)).toList(),
      );
    } else {
      return ListTile(
        title: Text(node.name),
        leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.blue),
        contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
        onTap: () async {
          await provider.selectFile(node.path);
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FileViewerScreen()),
            );
          }
        },
      );
    }
  }
}
