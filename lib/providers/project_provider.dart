import 'package:flutter/material.dart';
import 'dart:io';
import '../models/file_node.dart';
import '../services/file_service.dart';

class ProjectProvider with ChangeNotifier {
  final FileService _fileService = FileService();
  String? _projectPath;
  FileNode? _rootNode;
  bool _isLoading = false;

  String? _selectedFilePath;
  String? _selectedFileContent;

  String? get projectPath => _projectPath;
  FileNode? get rootNode => _rootNode;
  bool get isLoading => _isLoading;

  String? get selectedFilePath => _selectedFilePath;
  String? get selectedFileContent => _selectedFileContent;

  Future<void> openProject() async {
    _isLoading = true;
    notifyListeners();

    try {
      final path = await _fileService.pickDirectory();
      if (path != null) {
        _projectPath = path;
        final name = path.split(Platform.pathSeparator).last;
        
        final children = await _fileService.listDirectoryContents(path);
        _rootNode = FileNode(
          name: name,
          path: path,
          isDirectory: true,
          children: children,
          isExpanded: true,
        );
      }
    } catch (e) {
      debugPrint('Error picking workspace: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNodeChildren(FileNode node) async {
    if (!node.isDirectory) return;
    if (node.children.isNotEmpty) {
      node.isExpanded = !node.isExpanded;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final children = await _fileService.listDirectoryContents(node.path);
      node.children.addAll(children);
      node.isExpanded = true;
    } catch (e) {
      debugPrint('Error loading items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectFile(String filePath) async {
    _isLoading = true;
    _selectedFilePath = filePath;
    _selectedFileContent = null;
    notifyListeners();

    try {
      final content = await _fileService.readFileContent(filePath);
      _selectedFileContent = content;
    } catch (e) {
      _selectedFileContent = "Error reading file: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void closeProject() {
    _projectPath = null;
    _rootNode = null;
    _selectedFilePath = null;
    _selectedFileContent = null;
    notifyListeners();
  }
}
