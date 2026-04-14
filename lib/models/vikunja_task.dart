class CreateTaskRequest {
  final String title;
  final String? description;
  CreateTaskRequest({required this.title, this.description});
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'title': title};
    if (description != null) map['description'] = description;
    return map;
  }
}

class TaskResponse {
  final int id;
  final String title;
  TaskResponse({required this.id, required this.title});

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    return TaskResponse(
      id: json['id'] as int,
      title: json['title'] as String,
    );
  }
}

class TaskSummary {
  final int id;
  final String title;
  TaskSummary({required this.id, required this.title});

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    return TaskSummary(
      id: json['id'] as int,
      title: json['title'] as String,
    );
  }
}
