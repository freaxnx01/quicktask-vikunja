import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TaskHistoryEntry {
  final String taskName;
  final String projectName;
  final int timestamp;

  TaskHistoryEntry({
    required this.taskName,
    required this.projectName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'taskName': taskName,
    'projectName': projectName,
    'timestamp': timestamp,
  };

  factory TaskHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TaskHistoryEntry(
      taskName: json['taskName'] as String,
      projectName: json['projectName'] as String,
      timestamp: json['timestamp'] as int,
    );
  }
}

class TaskHistory {
  static const _key = 'task_history';
  static const _maxEntries = 20;

  Future<void> addEntry(TaskHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getEntries();
    final updated = [entry, ...entries];
    final trimmed = updated.length > _maxEntries
        ? updated.sublist(0, _maxEntries)
        : updated;
    await prefs.setString(
      _key,
      json.encode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<TaskHistoryEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final List<dynamic> data = json.decode(raw);
      return data.map((j) => TaskHistoryEntry.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }
}
