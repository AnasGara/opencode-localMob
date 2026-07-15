import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/file_node.dart';

class FileService {
  static String getFileName(String? path) {
    if (path == null || path.isEmpty) return '';
    final index = path.lastIndexOf(RegExp(r'[/\\]'));
    if (index == -1) return path;
    return path.substring(index + 1);
  }

  Future<String?> pickDirectory() async {
    return await FilePicker.platform.getDirectoryPath();
  }

  Future<FilePickerResult?> pickFile() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
  }

  Future<List<FileNode>> listDirectoryContents(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];

    final List<FileNode> nodes = [];
    try {
      final List<FileSystemEntity> entities = await dir.list().toList();
      
      // Sort folders first, then files alphabetically
      entities.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

      for (var entity in entities) {
        final name = getFileName(entity.path);
        if (name.startsWith('.')) continue; // skip hidden files (.git, etc)

        nodes.add(FileNode(
          name: name,
          path: entity.path,
          isDirectory: entity is Directory,
        ));
      }
    } catch (e) {
      debugPrint('Error parsing folder: $e');
    }
    return nodes;
  }

  Future<String> readFileContent(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.readAsString();
    }
    throw FileSystemException('File does not exist', filePath);
  }
}
