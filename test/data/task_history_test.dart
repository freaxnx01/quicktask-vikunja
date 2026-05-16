import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quicktask_vikunja/data/task_history.dart';

TaskHistoryEntry _entry(String name, int ts) =>
    TaskHistoryEntry(taskName: name, projectName: 'P', timestamp: ts);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('addEntry inserts new entries at the front (most-recent-first)',
      () async {
    final history = TaskHistory();
    await history.addEntry(_entry('first', 1));
    await history.addEntry(_entry('second', 2));
    final entries = await history.getEntries();
    expect(entries.map((e) => e.taskName), ['second', 'first']);
  });

  test('addEntry caps the list at 20 entries (drops the oldest)', () async {
    final history = TaskHistory();
    for (var i = 0; i < 25; i++) {
      await history.addEntry(_entry('e$i', i));
    }
    final entries = await history.getEntries();
    expect(entries, hasLength(20));
    // Newest (e24) at front, oldest survivor (e5) at end.
    expect(entries.first.taskName, 'e24');
    expect(entries.last.taskName, 'e5');
  });

  test('getEntries returns [] when the prefs payload is corrupt', () async {
    SharedPreferences.setMockInitialValues({
      'task_history': 'this is not json',
    });
    final entries = await TaskHistory().getEntries();
    expect(entries, isEmpty,
        reason: 'corrupt prefs must not crash the app — degrade to empty');
  });

  test('clear removes all entries', () async {
    final history = TaskHistory();
    await history.addEntry(_entry('x', 1));
    await history.clear();
    expect(await history.getEntries(), isEmpty);
  });

  test('round-trips url and projectName', () async {
    final history = TaskHistory();
    await history.addEntry(TaskHistoryEntry(
      taskName: 'My task',
      projectName: 'Inbox',
      url: 'https://example.com/x',
      timestamp: 42,
    ));
    final entries = await history.getEntries();
    expect(entries.single.url, 'https://example.com/x');
    expect(entries.single.projectName, 'Inbox');
    expect(entries.single.timestamp, 42);
  });
}
