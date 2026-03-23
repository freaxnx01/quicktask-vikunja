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

  Future<TaskResponse> createTask(int projectId, String title) {
    return _api.createTask(projectId, CreateTaskRequest(title: title));
  }
}
