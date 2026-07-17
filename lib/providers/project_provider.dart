import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/file_node.dart';
import '../services/file_service.dart';

class ProjectProvider with ChangeNotifier {
  final FileService _fileService = FileService();
  String? _projectPath;
  FileNode? _rootNode;
  bool _isLoading = false;

  String? _selectedFilePath;
  String? _selectedFileContent;
  Uint8List? _selectedFileBytes;
  String? _selectedFileMimeType;

  String? get projectPath => _projectPath;
  FileNode? get rootNode => _rootNode;
  bool get isLoading => _isLoading;

  String? get selectedFilePath => _selectedFilePath;
  String? get selectedFileContent => _selectedFileContent;
  Uint8List? get selectedFileBytes => _selectedFileBytes;
  String? get selectedFileMimeType => _selectedFileMimeType;

  Future<void> openProject() async {
    _isLoading = true;
    notifyListeners();

    try {
      final path = await _fileService.pickDirectory();
      if (path != null) {
        _projectPath = path;
        final name = FileService.getFileName(path);
        
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

  void selectFileBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    _selectedFilePath = fileName;
    _selectedFileBytes = bytes;
    _selectedFileMimeType = mimeType;
    _selectedFileContent = "[Attached Media File: $fileName]";
    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadFile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _fileService.pickFile();
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await selectFile(file.path!);
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
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

  Future<void> selectFile(String filePath) async {
    _isLoading = true;
    _selectedFilePath = filePath;
    _selectedFileContent = null;
    _selectedFileBytes = null;
    _selectedFileMimeType = _getMimeType(filePath);
    notifyListeners();

    try {
      final file = File(filePath);
      if (await file.exists()) {
        final isBinary = _isBinaryFile(filePath);
        if (isBinary) {
          _selectedFileBytes = await file.readAsBytes();
          _selectedFileContent = "[Attached Media File: ${FileService.getFileName(filePath)}]";
        } else {
          _selectedFileContent = await file.readAsString();
        }
      }
    } catch (e) {
      _selectedFileContent = "Error reading file: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedFile() {
    _selectedFilePath = null;
    _selectedFileContent = null;
    _selectedFileBytes = null;
    _selectedFileMimeType = null;
    notifyListeners();
  }

  void closeProject() {
    _projectPath = null;
    _rootNode = null;
    _selectedFilePath = null;
    _selectedFileContent = null;
    _selectedFileBytes = null;
    _selectedFileMimeType = null;
    notifyListeners();
  }
}
