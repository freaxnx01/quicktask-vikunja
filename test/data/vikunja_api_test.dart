import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:quicktask_vikunja/data/secure_storage.dart';
import 'package:quicktask_vikunja/data/vikunja_api.dart';
import 'package:quicktask_vikunja/models/vikunja_task.dart';

class _FakeStorage extends SecureStorage {
  @override
  Future<String?> get instanceUrl async => 'https://vikunja.test';
  @override
  Future<String?> get apiToken async => 'test-token';
}

VikunjaApi _apiWith(MockClient client) =>
    VikunjaApi(_FakeStorage(), client: client);

void main() {
  group('VikunjaApi.getProjects', () {
    test('sends per_page and page in the query string', () async {
      Uri? captured;
      final client = MockClient((req) async {
        captured = req.url;
        return http.Response('[]', 200);
      });
      await _apiWith(client).getProjects(perPage: 25, page: 3);
      expect(captured!.queryParameters['per_page'], '25');
      expect(captured!.queryParameters['page'], '3');
    });

    test('parses the returned project list', () async {
      final client = MockClient((_) async => http.Response(
            json.encode([
              {'id': 1, 'title': 'P1', 'is_archived': false},
              {'id': 2, 'title': 'P2', 'is_archived': true},
            ]),
            200,
          ));
      final projects = await _apiWith(client).getProjects();
      expect(projects, hasLength(2));
      expect(projects[0].id, 1);
      expect(projects[1].isArchived, isTrue);
    });

    test('throws on non-200 status', () async {
      final client = MockClient((_) async => http.Response('nope', 401));
      final api = _apiWith(client);
      expect(api.getProjects(), throwsA(isA<Exception>()));
    });

    test('sends Bearer token in Authorization header', () async {
      String? sentAuth;
      final client = MockClient((req) async {
        sentAuth = req.headers['Authorization'];
        return http.Response('[]', 200);
      });
      await _apiWith(client).getProjects();
      expect(sentAuth, 'Bearer test-token');
    });
  });

  group('VikunjaApi.createTask', () {
    test('PUTs the task and returns parsed response', () async {
      final client = MockClient((req) async {
        expect(req.method, 'PUT');
        expect(req.url.path, '/api/v1/projects/42/tasks');
        final body = json.decode(req.body) as Map<String, dynamic>;
        expect(body['title'], 'Hello');
        expect(body['description'], 'https://x.test');
        return http.Response(
          json.encode({'id': 999, 'title': 'Hello'}),
          201,
        );
      });
      final task = await _apiWith(client).createTask(
        42,
        CreateTaskRequest(title: 'Hello', description: 'https://x.test'),
      );
      expect(task.id, 999);
      expect(task.title, 'Hello');
    });

    test('omits description when null', () async {
      Map<String, dynamic>? sent;
      final client = MockClient((req) async {
        sent = json.decode(req.body) as Map<String, dynamic>;
        return http.Response(json.encode({'id': 1, 'title': 'X'}), 200);
      });
      await _apiWith(client).createTask(1, CreateTaskRequest(title: 'X'));
      expect(sent!.containsKey('description'), isFalse,
          reason: 'description must be omitted, not sent as null, '
              'so Vikunja does not overwrite an existing description');
    });

    test('throws on 5xx', () async {
      final client = MockClient((_) async => http.Response('boom', 500));
      expect(
        _apiWith(client).createTask(1, CreateTaskRequest(title: 'x')),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('VikunjaApi.getRecentProjectTasks', () {
    test('returns parsed tasks', () async {
      final client = MockClient((_) async => http.Response(
            json.encode([
              {'id': 1, 'title': 'A'},
              {'id': 2, 'title': 'B'},
            ]),
            200,
          ));
      final tasks = await _apiWith(client).getRecentProjectTasks(10);
      expect(tasks.map((t) => t.id), [1, 2]);
    });

    test('returns empty list on non-list payload', () async {
      // Vikunja occasionally returns {} instead of [] when a project is empty.
      final client = MockClient((_) async => http.Response('{}', 200));
      final tasks = await _apiWith(client).getRecentProjectTasks(10);
      expect(tasks, isEmpty);
    });

    test('passes limit + sort filters in query string', () async {
      Uri? captured;
      final client = MockClient((req) async {
        captured = req.url;
        return http.Response('[]', 200);
      });
      await _apiWith(client).getRecentProjectTasks(7, limit: 5);
      expect(captured!.path, '/api/v1/projects/7/tasks');
      expect(captured!.queryParameters['per_page'], '5');
      // Vikunja's filter syntax keeps the inner '=' literal in the query.
      expect(captured!.query, contains('filter=done=false'));
      expect(captured!.query, contains('sort_by%5B%5D=created'));
      expect(captured!.query, contains('order_by%5B%5D=desc'));
    });
  });
}
