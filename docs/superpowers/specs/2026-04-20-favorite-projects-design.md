# Favorite projects in picker — design

## Purpose

Let the user mark projects as favorites (e.g. Inbox) so they always appear at the top of the project picker, regardless of recent-usage decay.

## User-facing behavior

On `ProjectPickerScreen`:

- Each project row shows a trailing star icon button:
  - `Icons.star` (primary color) when favorited.
  - `Icons.star_border` (onSurfaceVariant) when not favorited.
- Tapping the star toggles favorite state and immediately re-sorts the list.
- Tapping the rest of the row behaves as today (creates the task).

Sections, top to bottom:

1. **Favorites** — favorited projects, asc by lowercased title.
2. **Recent** — MRU projects **minus favorites**.
3. **All Projects** — the rest, asc by lowercased title (unchanged behavior, minus favorites).

A project appears in **exactly one** section — no duplication.

Search filter applies uniformly across all three sections.

## Data

New class `ProjectFavorites` in `lib/data/project_favorites.dart`, backed by `shared_preferences`:

- Storage key: `favorite_project_ids` — JSON array of ints.
- API:
  - `Future<Set<int>> getFavoriteIds()`
  - `Future<void> toggle(int projectId)` — add if absent, remove if present.
  - `Future<bool> isFavorite(int projectId)` — convenience for tests; picker uses the in-memory set.

Same wrap-the-plugin pattern as `ProjectUsageTracker` / `TaskHistory`. Non-sensitive, so `shared_preferences` is the right fit.

## Wiring

- Construct `ProjectFavorites()` in `main.dart` alongside the existing trackers, pass into `ProjectPickerScreen`.
- `ProjectPickerScreen` gains an optional constructor param `ProjectFavorites? favorites` with `late final _favorites = widget.favorites ?? ProjectFavorites();` (standard in-house injection pattern).
- `_initialize()` loads favorites in the existing `Future.wait` alongside projects and recent ids.
- State holds `Set<int> _favoriteIds`.

## Sectioning logic (replaces current `_recentProjects` / `_otherProjects`)

```
favorites = filtered.where((p) => _favoriteIds.contains(p.id))
            .sortedBy(title asc)
recent    = filtered.where((p) => !_favoriteIds.contains(p.id)
                                 && _recentIds.contains(p.id))
            // MRU order preserved from _recentIds
other     = filtered.where((p) => !_favoriteIds.contains(p.id)
                                 && !_recentIds.contains(p.id))
            .sortedBy(title asc)
```

Toggle handler calls `_favorites.toggle(id)` then `setState(() => _favoriteIds = ...)` — no reload of projects needed.

## Errors

Favorites load failures are non-fatal: treat as empty set, log via `debugPrint` only if genuinely useful, and continue showing Recent/All.

## Tests

**Unit — `test/project_favorites_unit_test.dart`:**
- Starts empty.
- `toggle` adds then removes.
- Persistence across new instance (via `SharedPreferences.setMockInitialValues` seeding).
- Malformed stored JSON → treated as empty, does not throw.

**Widget — extension to `test/project_picker_screen_test.dart` (or new file):**
- With one favorite, it appears in the `Favorites` section and not in `Recent` or `All Projects`.
- Tapping the star on an unfavorited project moves it into `Favorites`.
- Tapping the star on a favorited project moves it back to `Recent` (if in `_recentIds`) or `All Projects`.
- Favorites respect the search filter.
- Tapping the row (not the star) still creates the task.

Hand-rolled fakes for `ProjectFavorites` (implementing the same public surface), consistent with the existing fakes for other data classes.

## Out of scope

- Drag-to-reorder within Favorites.
- Syncing favorites to Vikunja server-side.
- Default-seeding "Inbox" as a favorite — user stars it themselves.

## Migration

No migration needed — absent key means empty favorites.
