class Project {
  final int id;
  final String title;
  final bool isArchived;

  Project({required this.id, required this.title, this.isArchived = false});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      title: json['title'] as String,
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }
}
