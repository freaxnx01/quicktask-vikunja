import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quicktask_vikunja/data/project_favorites.dart';
import 'package:quicktask_vikunja/data/project_usage_tracker.dart';
import 'package:quicktask_vikunja/data/secure_storage.dart';
import 'package:quicktask_vikunja/data/task_history.dart';
import 'package:quicktask_vikunja/data/title_fetcher.dart';
import 'package:quicktask_vikunja/data/vikunja_api.dart';
import 'package:quicktask_vikunja/data/vikunja_repository.dart';
import 'package:quicktask_vikunja/models/project.dart';
import 'package:quicktask_vikunja/models/shared_content.dart';
import 'package:quicktask_vikunja/models/vikunja_task.dart';
import 'package:quicktask_vikunja/ui/project_picker_screen.dart';

class _FakeStorage extends SecureStorage {
  @override
  Future<String?> get instanceUrl async => 'https://x';
  @override
  Future<String?> get apiToken async => 't';
  @override
  Future<bool> get isConfigured async => true;
}

class _FakeFetcher extends TitleFetcher {
  @override
  Future<ResolvedTask> resolveTask(String text, String? extra) async =>
      ResolvedTask(title: text);
}

class _FakeRepo extends VikunjaRepository {
  _FakeRepo({required this.projects, this.failCreate = false})
      : super(VikunjaApi(_FakeStorage()));

  final List<Project> projects;
  final bool failCreate;
  int createCalls = 0;

  @override
  Future<List<Project>> getAllProjects() async => projects;

  @override
  Future<TaskResponse> createTask(int projectId, String title, {String? description}) async {
    createCalls++;
    if (failCreate) throw Exception('fail');
    return TaskResponse(id: 1, title: title);
  }

  @override
  Future<List<TaskSummary>> getRecentProjectTasks(int projectId, {int limit = 10}) async => [];

  @override
  Future<void> uploadAttachments(int taskId, List<String> filePaths) async {}
}

Widget _wrap(
  _FakeRepo repo, {
  String text = 'note',
  ProjectFavorites? favorites,
  ProjectUsageTracker? usageTracker,
}) =>
    MaterialApp(
      home: ProjectPickerScreen(
        shared: SharedContent(text: text),
        repository: repo,
        titleFetcher: _FakeFetcher(),
        usageTracker: usageTracker ?? ProjectUsageTracker(),
        favorites: favorites,
        taskHistory: TaskHistory(),
        onDone: () {},
      ),
    );

Finder _starOnTile(String projectTitle) => find.descendant(
      of: find.widgetWithText(ListTile, projectTitle),
      matching: find.byType(IconButton),
    );

List<String> _headerOrder(WidgetTester tester) {
  const headers = {'Favorites', 'Recent', 'All Projects'};
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .where(headers.contains)
      .toList();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('search field filters the project list', (tester) async {
    final repo = _FakeRepo(projects: [
      Project(id: 1, title: 'Alpha'),
      Project(id: 2, title: 'Beta'),
      Project(id: 3, title: 'Gamma'),
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Search projects...'), 'be');
    await tester.pump();

    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Gamma'), findsNothing);
  });

  testWidgets('non-recent projects are sorted alphabetically', (tester) async {
    final repo = _FakeRepo(projects: [
      Project(id: 3, title: 'Charlie'),
      Project(id: 1, title: 'Alice'),
      Project(id: 2, title: 'Bob'),
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    final tiles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(tiles, ['Alice', 'Bob', 'Charlie']);
  });

  testWidgets('rejects empty title without calling createTask', (tester) async {
    final repo = _FakeRepo(projects: [Project(id: 1, title: 'Inbox')]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // Wipe the title.
    await tester.enterText(find.widgetWithText(TextField, 'Task title'), '');
    await tester.pump();

    // Tap project — should refuse and surface an error, not hit the API.
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 0,
        reason: 'empty title must short-circuit before any network call');
    expect(find.text('Task title cannot be empty'), findsOneWidget);
  });

  testWidgets('favorites appear in their own section above Recent and All', (tester) async {
    final repo = _FakeRepo(projects: [
      Project(id: 1, title: 'Alpha'),
      Project(id: 2, title: 'Beta'),
      Project(id: 3, title: 'Inbox'),
    ]);
    final favorites = ProjectFavorites();
    await favorites.toggle(3); // Inbox is a favorite
    final usage = ProjectUsageTracker();
    await usage.recordUsage(2); // Beta is recent

    await tester.pumpWidget(_wrap(repo, favorites: favorites, usageTracker: usage));
    await tester.pumpAndSettle();

    expect(_headerOrder(tester), ['Favorites', 'Recent', 'All Projects']);

    // Inbox only appears once — in Favorites.
    expect(find.widgetWithText(ListTile, 'Inbox'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Beta'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Alpha'), findsOneWidget);
  });

  testWidgets('favorite is not duplicated when it is also recent', (tester) async {
    final repo = _FakeRepo(projects: [
      Project(id: 1, title: 'Inbox'),
      Project(id: 2, title: 'Other'),
    ]);
    final favorites = ProjectFavorites();
    await favorites.toggle(1);
    final usage = ProjectUsageTracker();
    await usage.recordUsage(1); // Inbox is both favorite AND recent

    await tester.pumpWidget(_wrap(repo, favorites: favorites, usageTracker: usage));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Inbox'), findsOneWidget,
        reason: 'favorite that is also recent must not be duplicated');
    // No Recent header when the only recent item is already in Favorites.
    expect(_headerOrder(tester), ['Favorites', 'All Projects']);
  });

  testWidgets('tapping star moves a project into Favorites immediately', (tester) async {
    final repo = _FakeRepo(projects: [
      Project(id: 1, title: 'Alpha'),
      Project(id: 2, title: 'Beta'),
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(_headerOrder(tester), ['All Projects']);

    await tester.tap(_starOnTile('Beta'));
    await tester.pumpAndSettle();

    expect(_headerOrder(tester), ['Favorites', 'All Projects']);
    // Beta should now sit in the Favorites section — verify by ordering.
    final tiles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(tiles, ['Beta', 'Alpha']);

    // Persisted.
    expect(await ProjectFavorites().getFavoriteIds(), {2});
  });

  testWidgets('tapping star twice unfavorites and returns project to All', (tester) async {
    final repo = _FakeRepo(projects: [Project(id: 1, title: 'Inbox')]);
    final favorites = ProjectFavorites();
    await favorites.toggle(1);

    await tester.pumpWidget(_wrap(repo, favorites: favorites));
    await tester.pumpAndSettle();

    expect(_headerOrder(tester), ['Favorites']);

    await tester.tap(_starOnTile('Inbox'));
    await tester.pumpAndSettle();

    expect(_headerOrder(tester), ['All Projects']);
    expect(await favorites.getFavoriteIds(), isEmpty);
  });

  testWidgets('tapping a project row (not the star) still creates the task', (tester) async {
    final repo = _FakeRepo(projects: [Project(id: 1, title: 'Inbox')]);
    final favorites = ProjectFavorites();
    await favorites.toggle(1);

    await tester.pumpWidget(_wrap(repo, favorites: favorites));
    await tester.pumpAndSettle();

    // Tap the title text, not the star icon.
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
  });

  testWidgets('search filter applies to favorites section too', (tester) async {
    final repo = _FakeRepo(projects: [
      Project(id: 1, title: 'Inbox'),
      Project(id: 2, title: 'Archive'),
    ]);
    final favorites = ProjectFavorites();
    await favorites.toggle(1);
    await favorites.toggle(2);

    await tester.pumpWidget(_wrap(repo, favorites: favorites));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Search projects...'), 'inb');
    await tester.pump();

    expect(find.widgetWithText(ListTile, 'Inbox'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Archive'), findsNothing);
  });

  testWidgets('createTask failure keeps user on picker with error message', (tester) async {
    final repo = _FakeRepo(
      projects: [Project(id: 1, title: 'Inbox')],
      failCreate: true,
    );
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectPickerScreen), findsOneWidget);
    expect(find.textContaining('Failed to create task'), findsOneWidget);
  });
}
