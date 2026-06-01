# Contributing to QuickTask Vikunja

Personal-use project — see [`PROJECT-OVERVIEW.md`](PROJECT-OVERVIEW.md) for
context. This guide captures the day-to-day mechanics: how to set the project
up, how to run the tests, and the branch/commit conventions used here.

Agents working on this repo: read [`CLAUDE.md`](CLAUDE.md) first — it is the
canonical source of project conventions. This file is the human-friendly
summary of the same rules.

---

## Setup

Prerequisites:

- Flutter (stable channel), Dart `^3.6`
- Android SDK + an emulator or physical device (for the share-target flow)
- Optional: Windows/Linux desktop toolchain for the manual-entry fallback

First-time setup:

```bash
flutter pub get
```

Run the app on a connected device or emulator:

```bash
flutter run                 # default device
flutter run -d windows      # specific device
flutter run --release       # release mode locally
```

Release builds always go through the project `justfile` so
`lib/build_info.dart` gets stamped with version + UTC timestamp:

```bash
just apk                    # Android release APK
just windows                # Windows release build
```

Do not invoke `flutter build` directly for releases — it leaves
`build_info.dart` stale.

---

## Running tests

Tests live under `test/` and use `flutter_test` with hand-rolled fakes (no
codegen mocking framework). The full suite must pass before any PR is merged.

```bash
flutter analyze                        # static analysis, zero issues required
dart format --set-exit-if-changed lib test
flutter test                           # full suite
flutter test test/<file>_test.dart     # single file
flutter test --coverage                # writes coverage/lcov.info
```

Test conventions:

- Write the failing test first; fix the implementation, not the test
- Inject fakes through optional constructor parameters (see existing widget
  tests for the pattern)
- For `shared_preferences`-backed code, call
  `SharedPreferences.setMockInitialValues({})` in `setUp`
- Always `addTearDown(...)` disposables (e.g. `StreamController`s)

---

## Branch naming

Branch from `main`, PR back to `main`, delete the branch after merge.

```
feature/<issue-id>-short-description
fix/<issue-id>-short-description
docs/<issue-id>-short-description
chore/<short-description>
release/<version>
```

`main` is protected: passing CI, at least one PR review, no direct pushes,
rebase or squash merge (no merge commits).

---

## Commit messages (Conventional Commits)

```
<type>(<scope>): <short summary>

[optional body explaining *why*]

[optional footer: Closes #<issue>]
```

Types: `feat`, `fix`, `test`, `refactor`, `chore`, `docs`, `ci`, `perf`.
Scope is the module or layer, e.g. `orders`, `ui`, `data`, `infra`.

Rules:

- Subject line in imperative mood, ≤72 chars, no trailing period
- Body explains *why*, not *what*
- Breaking changes: add a `BREAKING CHANGE:` footer or `!` after the type
- One concern per PR; PR title follows the same Conventional Commits format

SemVer mapping: `feat` → MINOR, `fix`/`perf` → PATCH,
`BREAKING CHANGE`/`!` → MAJOR. `chore`, `docs`, `ci`, `test`, `refactor` do
not bump the version.

---

## Pull requests

- Keep PRs small and focused
- PR body should include `Closes #<issue>` so the issue closes on merge
- All checks (analyze, format, tests) must pass
- See [`CLAUDE.md`](CLAUDE.md) for the full PR template and review checklist
