import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectFavorites {
  static const _key = 'favorite_project_ids';

  Future<Set<int>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return <int>{};
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) return <int>{};
      return decoded.whereType<int>().toSet();
    } catch (_) {
      return <int>{};
    }
  }

  Future<bool> isFavorite(int projectId) async {
    final ids = await getFavoriteIds();
    return ids.contains(projectId);
  }

  Future<void> toggle(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await getFavoriteIds();
    if (!ids.add(projectId)) {
      ids.remove(projectId);
    }
    await prefs.setString(_key, json.encode(ids.toList()));
  }
}
