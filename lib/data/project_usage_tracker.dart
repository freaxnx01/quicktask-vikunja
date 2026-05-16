import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectUsageTracker {
  static const _key = 'project_usage';

  Future<void> recordUsage(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = _getData(prefs);
    data[projectId.toString()] = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString(_key, json.encode(data));
  }

  Future<List<int>> getRecentProjectIds({int limit = 5}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = _getData(prefs);
    final entries = data.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    return entries.take(limit).map((e) => int.parse(e.key)).toList();
  }

  Map<String, dynamic> _getData(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(json.decode(raw));
    } catch (_) {
      return {};
    }
  }
}
