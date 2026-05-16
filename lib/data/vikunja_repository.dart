import '../models/project.dart';
import '../models/vikunja_task.dart';
import 'vikunja_api.dart';

class VikunjaRepository {
  final VikunjaApi _api;

  VikunjaRepository(this._api);

  Future<bool> validateCredentials() => _api.validateCredentials();

  Future<List<Project>> getAllProjects() async {
    final allProjects = <Project>[];
    var page = 1;
    while (true) {
      final batch = await _api.getProjects(perPage: 100, page: page);
      allProjects.addAll(batch);
      if (batch.length < 100) break;
      page++;
    }
    return allProjects.where((p) => !p.isArchived).toList();
  }

  Future<TaskResponse> createTask(int projectId, String title,
      {String? description}) {
    return _api.createTask(
        projectId, CreateTaskRequest(title: title, description: description));
  }

  Future<List<TaskSummary>> getRecentProjectTasks(int projectId,
      {int limit = 10}) {
    return _api.getRecentProjectTasks(projectId, limit: limit);
  }

  Future<void> uploadAttachments(int taskId, List<String> filePaths) {
    return _api.uploadAttachments(taskId, filePaths);
  }
}
