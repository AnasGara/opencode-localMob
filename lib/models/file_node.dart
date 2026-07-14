class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final List<FileNode> children;
  bool isExpanded;

  FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    List<FileNode>? children,
    this.isExpanded = false,
  }) : children = children ?? [];
}
