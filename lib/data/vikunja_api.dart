import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import '../models/vikunja_task.dart';
import 'secure_storage.dart';

class VikunjaApi {
  final SecureStorage _storage;
  final http.Client _client;

  VikunjaApi(this._storage, {http.Client? client})
      : _client = client ?? http.Client();

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
    final response = await _client.get(
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
    final response = await _client.put(
      Uri.parse('$base/api/v1/projects/$projectId/tasks'),
      headers: headers,
      body: json.encode(task.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create task: ${response.statusCode}');
    }
    return TaskResponse.fromJson(json.decode(response.body));
  }

  Future<List<TaskSummary>> getRecentProjectTasks(int projectId,
      {int limit = 10}) async {
    final base = await _baseUrl();
    final headers = await _headers();
    final response = await _client.get(
      Uri.parse(
          '$base/api/v1/projects/$projectId/tasks?per_page=$limit&sort_by[]=created&order_by[]=desc&filter=done=false'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load tasks: ${response.statusCode}');
    }
    final decoded = json.decode(response.body);
    if (decoded is! List) return [];
    return decoded.map((j) => TaskSummary.fromJson(j)).toList();
  }

  Future<void> uploadAttachments(int taskId, List<String> filePaths) async {
    if (filePaths.isEmpty) return;
    final base = await _baseUrl();
    final token = await _storage.apiToken;
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$base/api/v1/tasks/$taskId/attachments'),
    );
    request.headers['Authorization'] = 'Bearer ${token ?? ''}';
    for (final path in filePaths) {
      request.files.add(await http.MultipartFile.fromPath('files', path));
    }
    final streamed = await request.send();
    if (streamed.statusCode != 200 && streamed.statusCode != 201) {
      final body = await streamed.stream.bytesToString();
      throw Exception(
          'Attachment upload failed (${streamed.statusCode}): $body');
    }
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
