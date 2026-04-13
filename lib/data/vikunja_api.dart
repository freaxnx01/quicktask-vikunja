import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import '../models/vikunja_task.dart';
import 'secure_storage.dart';

class VikunjaApi {
  final SecureStorage _storage;

  VikunjaApi(this._storage);

  Future<Map<String, String>> _headers() async {
    final token = await _storage.apiToken;
    return {
      'Authorization': 'Bearer ${token ?? ''}',
      'Content-Type': 'application/json',
    };
  }

  Future<String> _baseUrl() async {
    final url = await _storage.instanceUrl;
    return url ?? 'http://localhost';
  }

  Future<List<Project>> getProjects({int perPage = 100, int page = 1}) async {
    final base = await _baseUrl();
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$base/api/v1/projects?per_page=$perPage&page=$page'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load projects: ${response.statusCode}');
    }
    final List<dynamic> data = json.decode(response.body);
    return data.map((j) => Project.fromJson(j)).toList();
  }

  Future<TaskResponse> createTask(int projectId, CreateTaskRequest task) async {
    final base = await _baseUrl();
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$base/api/v1/projects/$projectId/tasks'),
      headers: headers,
      body: json.encode(task.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create task: ${response.statusCode}');
    }
    return TaskResponse.fromJson(json.decode(response.body));
  }

  Future<bool> validateCredentials() async {
    try {
      await getProjects(perPage: 1);
      return true;
    } catch (_) {
      return false;
    }
  }
}
