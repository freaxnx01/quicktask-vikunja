import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quicktask_vikunja/data/secure_storage.dart';
import 'package:quicktask_vikunja/data/share_intent_source.dart';
import 'package:quicktask_vikunja/data/task_history.dart';
import 'package:quicktask_vikunja/data/title_fetcher.dart';
import 'package:quicktask_vikunja/data/vikunja_api.dart';
import 'package:quicktask_vikunja/data/vikunja_repository.dart';
import 'package:quicktask_vikunja/main.dart';
import 'package:quicktask_vikunja/models/project.dart';
import 'package:quicktask_vikunja/models/vikunja_task.dart';
import 'package:quicktask_vikunja/ui/project_picker_screen.dart';
import 'package:quicktask_vikunja/ui/recent_tasks_screen.dart';
import 'package:quicktask_vikunja/ui/task_confirmation_screen.dart';

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> get instanceUrl async => 'https://example.com';
  @override
  Future<String?> get apiToken async => 'test-token';
  @override
  Future<bool> get isConfigured async => true;
}

class _FakeTitleFetcher extends TitleFetcher {
  @override
  Future<ResolvedTask> resolveTask(String sharedText, String? extraSubject) async {
    return ResolvedTask(title: 'Title for $sharedText', url: sharedText);
  }
}

class _StubApi extends VikunjaApi {
  _StubApi() : super(_FakeSecureStorage());
}

class _FakeRepository extends VikunjaRepository {
  _FakeRepository() : super(_StubApi());

  int _nextId = 100;
  final List<String> createdTitles = [];
  final List<List<String>> uploadedPathsByCall = [];
  int _failUploadsRemaining = 0;

  /// Make the next [count] uploadAttachments calls throw, then succeed.
  void failNextUploads(int count) => _failUploadsRemaining = count;

  @override
  Future<List<Project>> getAllProjects() async =>
      [Project(id: 1, title: 'Test Project')];

  @override
  Future<TaskResponse> createTask(int projectId, String title, {String? description}) async {
    final id = _nextId++;
    createdTitles.add(title);
    return TaskResponse(id: id, title: title);
  }

  @override
  Future<List<TaskSummary>> getRecentProjectTasks(int projectId, {int limit = 10}) async => [];

  @override
  Future<void> uploadAttachments(int taskId, List<String> filePaths) async {
    uploadedPathsByCall.add(List.of(filePaths));
    if (_failUploadsRemaining > 0) {
      _failUploadsRemaining--;
      throw Exception('upload failed');
    }
  }
}

class _FakeShareIntentSource implements ShareIntentSource {
  final _controller = StreamController<List<SharedMediaFile>>.broadcast();
  List<SharedMediaFile> initialMedia = [];
  bool resetCalled = false;

  @override
  Stream<List<SharedMediaFile>> getMediaStream() => _controller.stream;

  @override
  Future<List<SharedMediaFile>> getInitialMedia() async => initialMedia;

  @override
  void reset() {
    resetCalled = true;
  }

  void fireTextShare(String text) {
    _controller.add([SharedMediaFile(path: text, type: SharedMediaType.text)]);
  }

  void fireFileShare(List<String> paths, {SharedMediaType type = SharedMediaType.image}) {
    _controller.add([
      for (final p in paths) SharedMediaFile(path: p, type: type),
    ]);
  }

  Future<void> dispose() => _controller.close();
}

Widget _buildApp({
  required _FakeShareIntentSource shareSource,
  required _FakeRepository repository,
}) {
  return MaterialApp(
    home: HomePage(
      storage: _FakeSecureStorage(),
      repository: repository,
      titleFetcher: _FakeTitleFetcher(),
      taskHistory: null,
      usageTracker: null,
      shareSource: shareSource,
      enableShareListener: true,
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'does not leave stale TaskConfirmationScreen on stack across multiple shares',
    (tester) async {
      final shareSource = _FakeShareIntentSource();
      final repository = _FakeRepository();
      addTearDown(shareSource.dispose);

      await tester.pumpWidget(_buildApp(shareSource: shareSource, repository: repository));
      await _settle(tester);

      // Verify we start on the recent tasks screen.
      expect(find.byType(RecentTasksScreen), findsOneWidget);

      // First share: URL 1.
      shareSource.fireTextShare('https://url-one.example/page');
      await _settle(tester);
      expect(find.byType(ProjectPickerScreen), findsOneWidget);

      // Pick project → goes to TaskConfirmationScreen (URL 1).
      await tester.tap(find.text('Test Project'));
      await _settle(tester);
      expect(find.byType(TaskConfirmationScreen), findsOneWidget);

      // User does NOT tap Done. A second share arrives.
      shareSource.fireTextShare('https://url-two.example/page');
      await _settle(tester);
      expect(find.byType(ProjectPickerScreen), findsOneWidget);

      // Pick project again → TaskConfirmationScreen (URL 2).
      await tester.tap(find.text('Test Project'));
      await _settle(tester);
      expect(find.byType(TaskConfirmationScreen), findsOneWidget);

      // Tap Done — user should land on RecentTasksScreen, not a stale confirmation.
      await tester.tap(find.text('Done'));
      await _settle(tester);

      expect(find.byType(TaskConfirmationScreen), findsNothing,
          reason: 'No stale TaskConfirmationScreen should remain on the stack');
      expect(find.byType(RecentTasksScreen), findsOneWidget);
    },
  );

  testWidgets('reset() is called after handling the initial share intent', (tester) async {
    final shareSource = _FakeShareIntentSource()..initialMedia = [
      SharedMediaFile(path: 'https://example.com/x', type: SharedMediaType.text),
    ];
    final repository = _FakeRepository();
    addTearDown(shareSource.dispose);

    await tester.pumpWidget(_buildApp(shareSource: shareSource, repository: repository));
    await _settle(tester);

    expect(shareSource.resetCalled, isTrue,
        reason: 'reset() must be called after consuming initial media or it can replay');
  });

  testWidgets('records the new task in local history after Done', (tester) async {
    final shareSource = _FakeShareIntentSource();
    final repository = _FakeRepository();
    final history = TaskHistory(); // backed by SharedPreferences mock
    addTearDown(shareSource.dispose);

    await tester.pumpWidget(MaterialApp(
      home: HomePage(
        storage: _FakeSecureStorage(),
        repository: repository,
        titleFetcher: _FakeTitleFetcher(),
        taskHistory: history,
        shareSource: shareSource,
        enableShareListener: true,
      ),
    ));
    await _settle(tester);

    shareSource.fireTextShare('https://reisereporter.de/article');
    await _settle(tester);
    await tester.tap(find.text('Test Project'));
    await _settle(tester);
    await tester.tap(find.text('Done'));
    await _settle(tester);

    final entries = await history.getEntries();
    expect(entries, hasLength(1));
    expect(entries.first.taskName, 'Title for https://reisereporter.de/article');
    expect(entries.first.url, 'https://reisereporter.de/article');
    expect(entries.first.projectName, 'Test Project');
  });

  testWidgets('RecentTasksScreen reloads after task is added', (tester) async {
    final shareSource = _FakeShareIntentSource();
    final repository = _FakeRepository();
    final history = TaskHistory();
    addTearDown(shareSource.dispose);

    await tester.pumpWidget(MaterialApp(
      home: HomePage(
        storage: _FakeSecureStorage(),
        repository: repository,
        titleFetcher: _FakeTitleFetcher(),
        taskHistory: history,
        shareSource: shareSource,
        enableShareListener: true,
      ),
    ));
    await _settle(tester);
    expect(find.text('No tasks yet.\nShare a URL or text from another app, or tap + to add one.'),
        findsOneWidget);

    shareSource.fireTextShare('https://wemolo.com/parking');
    await _settle(tester);
    await tester.tap(find.text('Test Project'));
    await _settle(tester);
    await tester.tap(find.text('Done'));
    await _settle(tester);

    expect(find.byType(RecentTasksScreen), findsOneWidget);
    expect(find.text('Title for https://wemolo.com/parking'), findsOneWidget,
        reason: 'Newly added task must appear in recent list without app restart');
  });

  testWidgets('picker pre-fills title from shared file name when no text', (tester) async {
    final shareSource = _FakeShareIntentSource();
    final repository = _FakeRepository();
    addTearDown(shareSource.dispose);

    await tester.pumpWidget(_buildApp(shareSource: shareSource, repository: repository));
    await _settle(tester);

    shareSource._controller.add([
      SharedMediaFile(path: '/tmp/cache/IMG_2024_07_13.jpg', type: SharedMediaType.image),
    ]);
    await _settle(tester);

    expect(find.byType(ProjectPickerScreen), findsOneWidget);
    expect(find.widgetWithText(TextField, 'IMG_2024_07_13.jpg'), findsOneWidget,
        reason: 'For pure-file shares, title should default to the file name');
  });

  testWidgets('cold-start share via getInitialMedia opens picker with shared URL', (tester) async {
    final shareSource = _FakeShareIntentSource()..initialMedia = [
      SharedMediaFile(path: 'https://cold.example/page', type: SharedMediaType.text),
    ];
    final repository = _FakeRepository();
    addTearDown(shareSource.dispose);

    await tester.pumpWidget(_buildApp(shareSource: shareSource, repository: repository));
    await _settle(tester);

    expect(find.byType(ProjectPickerScreen), findsOneWidget,
        reason: 'cold-start share must open the picker, not just sit on the home screen');
    expect(find.widgetWithText(TextField, 'Title for https://cold.example/page'),
        findsOneWidget);
    expect(shareSource.resetCalled, isTrue);
  });

  testWidgets('multi-file share creates one task and uploads N attachments', (tester) async {
    final shareSource = _FakeShareIntentSource();
    final repository = _FakeRepository();
    addTearDown(shareSource.dispose);

    await tester.pumpWidget(_buildApp(shareSource: shareSource, repository: repository));
    await _settle(tester);

    shareSource.fireFileShare([
      '/tmp/cache/IMG_001.jpg',
      '/tmp/cache/IMG_002.jpg',
      '/tmp/cache/IMG_003.jpg',
    ]);
    await _settle(tester);

    expect(find.byType(ProjectPickerScreen), findsOneWidget);
    // One chip per file shown to the user.
    expect(find.text('IMG_001.jpg'), findsOneWidget);
    expect(find.text('IMG_002.jpg'), findsOneWidget);
    expect(find.text('IMG_003.jpg'), findsOneWidget);

    await tester.tap(find.text('Test Project'));
    await _settle(tester);

    // Exactly one createTask, exactly one uploadAttachments call with all 3 paths.
    expect(repository.createdTitles, hasLength(1));
    expect(repository.uploadedPathsByCall, hasLength(1));
    expect(repository.uploadedPathsByCall.single, [
      '/tmp/cache/IMG_001.jpg',
      '/tmp/cache/IMG_002.jpg',
      '/tmp/cache/IMG_003.jpg',
    ]);
    // Confirmation surfaces success.
    expect(find.text('3 attachments uploaded'), findsOneWidget);
  });

  testWidgets('attachment upload failure shows error and Retry recovers', (tester) async {
    final shareSource = _FakeShareIntentSource();
    final repository = _FakeRepository()..failNextUploads(1);
    addTearDown(shareSource.dispose);

    await tester.pumpWidget(_buildApp(shareSource: shareSource, repository: repository));
    await _settle(tester);

    shareSource.fireFileShare(['/tmp/IMG.jpg']);
    await _settle(tester);
    await tester.tap(find.text('Test Project'));
    await _settle(tester);

    // Confirmation appears with the failure message + Retry button.
    expect(find.text('Attachment upload failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Tap Retry — second upload succeeds, error message clears.
    await tester.tap(find.text('Retry'));
    await _settle(tester);

    expect(find.text('Attachment upload failed'), findsNothing,
        reason: 'after a successful retry the error banner must clear');
    expect(find.text('1 attachment uploaded'), findsOneWidget);
    expect(repository.uploadedPathsByCall, hasLength(2),
        reason: 'one failed call + one retry call = 2 uploadAttachments invocations');
  });

  testWidgets('redirects share to setup screen when not configured', (tester) async {
    final shareSource = _FakeShareIntentSource();
    final repository = _FakeRepository();
    addTearDown(shareSource.dispose);

    await tester.pumpWidget(MaterialApp(
      home: HomePage(
        storage: _UnconfiguredSecureStorage(),
        repository: repository,
        titleFetcher: _FakeTitleFetcher(),
        shareSource: shareSource,
        enableShareListener: true,
      ),
    ));
    await _settle(tester);

    shareSource.fireTextShare('https://deferred.example/page');
    await _settle(tester);

    // Picker must NOT appear before the user has configured the app —
    // otherwise the user would hit a broken project list with no token.
    expect(find.byType(ProjectPickerScreen), findsNothing);
    expect(find.byType(RecentTasksScreen), findsNothing);
  });
}

class _UnconfiguredSecureStorage extends SecureStorage {
  @override
  Future<String?> get instanceUrl async => null;
  @override
  Future<String?> get apiToken async => null;
  @override
  Future<bool> get isConfigured async => false;
}
