class CreateTaskRequest {
  final String title;
  CreateTaskRequest({required this.title});
  Map<String, dynamic> toJson() => {'title': title};
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
