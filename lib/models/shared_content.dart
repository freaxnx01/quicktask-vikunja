/// Represents what the user shared into QuickTask from another app.
///
/// A share can contain plain text (typically a URL), one or more files,
/// or both (e.g. some apps send image + caption together).
class SharedContent {
  final String? text;
  final String? extraSubject;
  final List<SharedFile> files;

  const SharedContent({
    this.text,
    this.extraSubject,
    this.files = const [],
  });

  bool get hasFiles => files.isNotEmpty;
  bool get hasText => text != null && text!.trim().isNotEmpty;
}

class SharedFile {
  final String path;
  final String name;

  const SharedFile({required this.path, required this.name});

  factory SharedFile.fromPath(String path) {
    final segments = path.split('/');
    return SharedFile(
      path: path,
      name: segments.isEmpty ? path : segments.last,
    );
  }
}
