import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:quicktask_vikunja/data/secure_storage.dart';
import 'package:quicktask_vikunja/data/vikunja_api.dart';
import 'package:quicktask_vikunja/data/vikunja_repository.dart';

class _FakeStorage extends SecureStorage {
  @override
  Future<String?> get instanceUrl async => 'https://vikunja.test';
  @override
  Future<String?> get apiToken async => 'test-token';
}

VikunjaRepository _repoWith(MockClient client) =>
    VikunjaRepository(VikunjaApi(_FakeStorage(), client: client));

List<Map<String, Object>> _fullBatch(int startId) => List.generate(
      100,
      (i) =>
          {'id': startId + i, 'title': 'P${startId + i}', 'is_archived': false},
    );

void main() {
  group('VikunjaRepository.getAllProjects', () {
    test('stops after the first page when the batch is already partial',
        () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        return http.Response(
          json.encode([
            {'id': 1, 'title': 'Solo', 'is_archived': false},
          ]),
          200,
        );
      });

      final all = await _repoWith(client).getAllProjects();

      expect(calls, 1,
          reason: 'a partial first page must not trigger another fetch');
      expect(all.map((p) => p.id), [1]);
    });

    test(
        'keeps paginating while full batches come back, stops on the partial one',
        () async {
      final pages = <int>[];
      final client = MockClient((req) async {
        final page = int.parse(req.url.queryParameters['page']!);
        pages.add(page);
        if (page == 1) return http.Response(json.encode(_fullBatch(1)), 200);
        if (page == 2) return http.Response(json.encode(_fullBatch(101)), 200);
        // Page 3: partial (5 items) → loop exits after this batch.
        return http.Response(
          json.encode([
            {'id': 201, 'title': 'P201', 'is_archived': false},
            {'id': 202, 'title': 'P202', 'is_archived': false},
            {'id': 203, 'title': 'P203', 'is_archived': false},
            {'id': 204, 'title': 'P204', 'is_archived': false},
            {'id': 205, 'title': 'P205', 'is_archived': false},
          ]),
          200,
        );
      });

      final all = await _repoWith(client).getAllProjects();

      expect(pages, [1, 2, 3], reason: 'should fetch exactly the three pages');
      expect(all, hasLength(205));
      expect(all.first.id, 1);
      expect(all.last.id, 205);
    });

    test('always requests per_page=100 regardless of caller', () async {
      final seenPerPage = <String?>[];
      final client = MockClient((req) async {
        seenPerPage.add(req.url.queryParameters['per_page']);
        return http.Response(
            json.encode([
              {'id': 1, 'title': 'P1', 'is_archived': false},
            ]),
            200);
      });

      await _repoWith(client).getAllProjects();

      expect(seenPerPage, ['100']);
    });

    test('filters archived projects out of the final list', () async {
      final client = MockClient((_) async => http.Response(
            json.encode([
              {'id': 1, 'title': 'Active', 'is_archived': false},
              {'id': 2, 'title': 'Archived', 'is_archived': true},
              {'id': 3, 'title': 'Also active', 'is_archived': false},
            ]),
            200,
          ));

      final all = await _repoWith(client).getAllProjects();

      expect(all.map((p) => p.id), [1, 3]);
    });

    test('returns an empty list when the first page is empty', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('[]', 200);
      });

      final all = await _repoWith(client).getAllProjects();

      expect(calls, 1, reason: 'an empty partial batch must not loop forever');
      expect(all, isEmpty);
    });

    test('propagates API errors instead of swallowing them', () async {
      final client = MockClient((_) async => http.Response('boom', 500));
      expect(_repoWith(client).getAllProjects(), throwsA(isA<Exception>()));
    });
  });
}
