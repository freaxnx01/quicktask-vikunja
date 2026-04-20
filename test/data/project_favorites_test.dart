import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quicktask_vikunja/data/project_favorites.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts empty when no prefs payload exists', () async {
    expect(await ProjectFavorites().getFavoriteIds(), isEmpty);
  });

  test('toggle adds a project id, then removes it on second call', () async {
    final favorites = ProjectFavorites();
    await favorites.toggle(42);
    expect(await favorites.getFavoriteIds(), {42});
    await favorites.toggle(42);
    expect(await favorites.getFavoriteIds(), isEmpty);
  });

  test('toggle persists across instances', () async {
    await ProjectFavorites().toggle(7);
    await ProjectFavorites().toggle(9);
    expect(await ProjectFavorites().getFavoriteIds(), {7, 9});
  });

  test('isFavorite reflects stored state', () async {
    final favorites = ProjectFavorites();
    expect(await favorites.isFavorite(5), isFalse);
    await favorites.toggle(5);
    expect(await favorites.isFavorite(5), isTrue);
  });

  test('getFavoriteIds returns empty set when payload is corrupt', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_project_ids': 'not json',
    });
    expect(await ProjectFavorites().getFavoriteIds(), isEmpty);
  });
}
