[//]: # (Source of truth: .ai/base-instructions.md + .ai/stacks/flutter.md — update those, then regenerate by re-running /sync-ai-instructions)

# SKILL.md — OpenClaw Agent Skill

This skill configures OpenClaw for this project.

---

# AI Agent Base Instructions

Canonical, **stack-agnostic** reference for all AI coding agents. Applies to every project regardless of language or framework. Stack-specific overlays live in `.ai/stacks/<stack>.md` and are loaded alongside this file. A project loads **base + exactly one stack overlay**. Tool-specific files (`CLAUDE.md`, `.github/copilot-instructions.md`, `SKILL.md`) derive from base + the chosen stack.

> **Workflow role:** If a `WORKFLOW-ROLE.md` exists at the repo root, read it before continuing — it describes this repo's place in the personal dev workflow (implementer / consumer / workflow infrastructure). See `ai-instructions/workflows/personal-dev-workflow.md` for the workflow doc itself.
>
> **Project context:** If a `PROJECT-OVERVIEW.md` exists at the repo root, read it before continuing — it describes this repo's product/project context (name, purpose, stakeholders, vision, core customer need, key features, architecture in one paragraph). Per-feature PRDs live under `docs/specs/` or `designs/`; ADRs under `docs/adr/`.

---

## Working Method (before any code)

Meta-rules for *how* to approach a task. Framing adapted from [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills).

- **State assumptions explicitly.** If multiple interpretations exist, present them — don't pick silently.
- **Ask when unclear.** Don't hide confusion behind plausible-looking code.
- **Push back when a simpler approach exists.** Minimum code that solves the problem; nothing speculative (no unrequested flexibility, configurability, or error handling for impossible cases).
- **Surgical edits.** Every changed line must trace to the request. Don't "improve" adjacent code, comments, or formatting. Match existing style. Remove orphans *your* change created — leave pre-existing dead code alone (mention it instead).
- **Goal-driven execution.** Restate the task as a verifiable success criterion before starting. For multi-step work, write a brief numbered plan with a `verify:` check per step, then loop until each check passes.

---

## Clean Code Principles

Apply to all generated and modified code, regardless of language:

- **Small methods/functions** — each does one thing at one level of abstraction; aim for ≤20 lines
- **Guard clauses** — validate and return/throw early at the top; avoid nested `if/else` pyramids
- **Command-Query Separation** — a function either performs an action (command, returns nothing) or returns data (query), never both
- **No flag arguments** — avoid boolean parameters that switch behaviour; split into two clearly named functions instead
- **Meaningful names** — names reveal intent; no abbreviations (`cnt`, `mgr`, `svc`) except universally understood ones (`id`, `url`, `dto`)
- **One level of abstraction per function** — don't mix high-level orchestration with low-level detail; extract helpers
- **Fail fast** — detect invalid state as early as possible and throw specific errors; don't let bad data travel deep into the call stack
- **DRY** — if the same logic exists in two places, extract it; but prefer duplication over the wrong abstraction — wait until the pattern is clear before generalising
- **No dead code** — delete unreachable branches, unused parameters, and vestigial methods; git has history
- **No commented-out code blocks** — delete them, git has history

---

## Testing — TDD, Tests First, No Shortcuts

Applies to every language and framework:

1. Write the failing test first
2. Write the minimum implementation to make it pass
3. Refactor
4. **Never modify a test to make it green** — fix the implementation
5. **Never hardcode return values, mock results, or stub logic** to satisfy a test
6. **Never silently swallow exceptions** to make a test green
7. **After implementation, run the full test suite** — not just the new test
8. **If a test fails after 3 attempts, STOP** and explain what's going wrong instead of continuing to iterate
9. Test naming: `MethodName_StateUnderTest_ExpectedBehavior` (or the idiomatic equivalent for the target language)
10. E2E tests must be independent and idempotent — seed and clean up their own data

Framework-specific test project layout, mocking library choice, and assertion library live in the stack overlay.

---

## UI Development Workflow (Mandatory Phase Order)

**Never skip phases. Never write component code before wireframe approval.**

| Phase | Skill | Gate |
|---|---|---|
| 1 — Brainstorm | `/ui-brainstorm` | ASCII wireframe approved |
| 2 — Flow       | `/ui-flow`       | Mermaid diagrams approved |
| 3 — Build      | `/ui-build`      | Shell → logic → interactions → polish |
| 4 — Review     | `/ui-review`     | Checklist passes |

Skill files live in `.ai/skills/`. The skills themselves are stack-neutral — UI component library preferences (e.g. MudBlazor, shadcn/ui, Material, Flutter widgets) are captured in the active stack overlay.

### What to check before writing UI code

- [ ] Does a similar component already exist in a shared folder?
- [ ] Has the ASCII wireframe been approved?
- [ ] Has the Mermaid flow been approved?
- [ ] Are you building the shell first (no business logic yet)?
- [ ] Does the component need a unit/component test?

---

## Localization (i18n) & Regional Formatting

User-facing apps must support **`de` and `en`**. CI tooling and developer-only utilities are exempt.

### Language

- Default language resolved from the OS / browser locale at first launch
- User can override at runtime via an in-app language switcher
- The user's choice is persisted (cookie, preferences store, or user profile — stack-specific)

### Regional formatting (decoupled from language)

Regional formatting (date, time, number, currency separators) is selected from the OS region — **not** dictated by the language.

- Auto-detect any `de-*` OS region (`de-CH`, `de-DE`, `de-AT`, …) and use the matching culture
- If the language is `de` but the OS region is missing or unrecognized: fall back to **`de-CH`**
- For `en`: use the OS-provided region (typically `en-US` / `en-GB`) — do not force a default

### Rules

- All date / number / currency rendering goes through the platform's localization API — never hand-format with raw `string.Format` / `toString()` / template literals.
- Do not couple regional formatting to the UI language. A user can read German text with US formatting, or English text with Swiss formatting; both must work.
- Stack overlays specify the concrete API (`CultureInfo` + `RequestLocalization` for .NET, `flutter_localizations` + `intl` for Flutter, etc.).

---

## Versioning (SemVer)

All projects follow [Semantic Versioning 2.0.0](https://semver.org/): `MAJOR.MINOR.PATCH` — `MAJOR` = breaking, `MINOR` = new feature (backwards-compatible), `PATCH` = bug fix.

Conventional Commits mapping: `BREAKING CHANGE:` footer or `!` after type → MAJOR; `feat` → MINOR; `fix`, `perf` → PATCH; `chore`, `docs`, `ci`, `test`, `refactor` → no bump.

- Git tags follow `v<MAJOR>.<MINOR>.<PATCH>` (e.g. `v1.3.0`) — tag on `main` after merge
- Pre-release: `v1.0.0-alpha.1`, `v1.0.0-beta.2`, `v1.0.0-rc.1`
- **git-cliff** is the changelog and release notes tool — configured via `cliff.toml`
- Where the version is declared in the project (build file, manifest, etc.) is defined by the stack overlay — but it must be declared in **exactly one place**

---

## Changelog

All projects maintain a `CHANGELOG.md` in the repo root following [Keep a Changelog](https://keepachangelog.com) conventions. **Sections per release:** `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

- `[Unreleased]` section accumulates changes until a release is cut
- Auto-generation: **git-cliff** with `cliff.toml` configured for Conventional Commits
- CI integration: `orhun/git-cliff-action` in GitHub Actions generates release notes into GitHub Releases
- CI can validate that `[Unreleased]` is not empty before allowing a release branch

Example: [`.ai/references/base/changelog-example.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/base/changelog-example.md)

---

## 12-Factor App Compliance

Projects follow the [12-Factor App](https://www.12factor.net/) methodology: one repo per service, all deps declared, env-var config, attached backing services, separate build/release/run stages, stateless processes, port binding, scale via replicas not threads, fast disposability, dev/prod parity, logs to stdout, admin processes as one-offs.

Stack-specific enforcement details (logging library, migrations, etc.) live in the stack overlay.

Full per-factor table: [`.ai/references/base/12-factor.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/base/12-factor.md)

---

## Branching Strategy (GitHub Flow + protection rules)

```
main              ← always deployable, protected
  └── feature/<issue-id>-short-description
  └── fix/<issue-id>-short-description
  └── chore/<short-description>
  └── release/<version>   ← only if needed for staged releases
```

- `main` requires: passing CI, at least 1 PR review, no direct push
- Branch from `main`, PR back to `main`
- Delete branch after merge
- Rebase or squash merge — no merge commits on `main`

---

## Git Worktrees

### Worktree directory

- Use **project-local** worktrees under `.worktrees/` at the repo root (hidden directory)
- `.worktrees/` must be listed in `.gitignore` — add and commit it before creating the first worktree in a repo
- Use a **random, short branch name** when the user does not specify one (e.g. `wt/<8-hex-chars>`); do not prompt for a branch name

Agent tooling that automates worktree creation should discover these rules from `CLAUDE.md` / `AGENTS.md` (e.g. a `worktree.*director` grep) and honour them without asking.

---

## Commit Messages (Conventional Commits)

```
<type>(<scope>): <short summary>

[optional body]

[optional footer: Closes #<issue>]
```

**Types:** `feat`, `fix`, `test`, `refactor`, `chore`, `docs`, `ci`, `perf`
**Scope:** module or layer name, e.g. `orders`, `auth`, `infra`, `ui`

```
feat(orders): add order cancellation endpoint

Implements POST /api/v1/orders/{id}/cancel.
Validates order is in Pending state before cancelling.

Closes #42
```

- Subject line: imperative mood, ≤72 chars, no period
- Body: explain *why*, not *what*
- Breaking changes: add `BREAKING CHANGE:` footer (or `!` after the type)

---

## Pull Request Conventions

### PR Title

Follow Conventional Commits format: `feat(orders): add cancellation endpoint`

### PR Description Template

Body sections: **Summary** · **Changes** · **Testing** (unit, component/integration, E2E, local) · **Checklist** (tests pass, no new vulnerable deps, no secrets, migrations included if schema changed, API/OpenAPI spec still valid).

Template: [`.ai/references/base/pr-description-template.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/base/pr-description-template.md)

### Review Guidelines

- PRs should be small and focused — one concern per PR
- Reviewers check: architecture adherence, test quality, security, no shortcuts that make tests green
- Auto-assign reviewers via `CODEOWNERS`

---

## CI/CD (generic outline)

Pipeline stages: `build` → `test` → `security-scan` → `container-build` → `push`

- Build and test run on every PR
- Vulnerable-dependency scan fails the build on HIGH/CRITICAL
- Container image built and pushed only on `main` after tests pass
- E2E tests run against the built image before it is marked as a release candidate

Concrete CI configuration (GitHub Actions YAML, commands, package scanners) lives in the stack overlay.

---

## Documentation Structure

Repo-root `docs/` contains:
- `design/<feature-name>/` — UI wireframes (`wireframe.md`) & Mermaid flows (`flow.md`) per feature
- `adr/` — Architecture Decision Records
- `ai-notes/` — AI agent working notes

Rules:
- `README.md` and `CHANGELOG.md` live in the repo root
- UI design artifacts are saved per feature during the UI workflow phases
- AI agents write working notes to `docs/ai-notes/`, not `.ai/`
- `.ai/` is reserved for agent instructions and skill files only

Layout: [`.ai/references/base/documentation-structure.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/base/documentation-structure.md)

---

## Security (baseline)

- Transport security enforced (HTTPS + HSTS)
- No secrets in source files or per-environment config files — environment variables or a secrets manager only
- Validate all inputs at system boundaries before any domain logic
- Run a vulnerable-dependency scan in CI — fail the build on HIGH/CRITICAL findings
- Standard security response headers on every HTTP response

Language- and framework-specific enforcement (specific scanners, validation libraries, header mechanisms) lives in the stack overlay.

---

## Agent Guardrails

- Do not install additional packages without asking first
- Do not change the project's target runtime or framework version
- Do not modify build/project files unless the task requires it
- Do not introduce new architectural patterns unless explicitly asked
- Do not touch files outside the scope of the current task
- Keep changes minimal and focused — do not refactor unrelated code unless asked
- Never skip git hooks (`--no-verify`) unless the user explicitly asks
- Never commit secrets or credential files

Stack-specific guardrails (e.g. "do not add NuGet packages") live in the stack overlay.

---

## Project Scaffold Checklist (baseline)

Init-time checklist (every project, regardless of stack) — including baseline, .NET, and WebAPI layers — lives at [`.ai/references/scaffold-checklists.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/scaffold-checklists.md). Stack-specific additions are in the same file under their respective sections.


[//]: # (Stack overlay — loaded together with .ai/base-instructions.md for Flutter projects)

# Flutter Stack Overlay

Applies on top of `.ai/base-instructions.md` for Flutter / Dart projects targeting Android, iOS, desktop (Windows/macOS/Linux), and/or web.

---

## Tech Stack

| Layer | Technology |
|---|---|
| SDK | Flutter (stable channel), Dart `^3.6` |
| UI | Material 3 (`useMaterial3: true`) with Cupertino widgets where iOS-idiomatic |
| State management | `provider` for cross-tree state; plain `StatefulWidget` + constructor injection for screen-local state |
| Routing | Imperative `Navigator` + `MaterialPageRoute` (small apps); `go_router` only when deep links / nested navigation justify it |
| Networking | `package:http` with an injectable `http.Client` |
| HTML parsing (where needed) | `package:html` |
| Secure storage | `flutter_secure_storage` (tokens, credentials) |
| Non-sensitive local storage | `shared_preferences` (settings, history, recents) |
| Platform integration | First-party plugins (`receive_sharing_intent`, `url_launcher`, `path_provider`, etc.) wrapped behind injectable interfaces |
| Lints | `flutter_lints` via `analysis_options.yaml` |
| Testing | `flutter_test` widget tests + hand-rolled fakes (no mock-generation framework by default) |
| Build orchestration | `justfile` ([casey/just](https://github.com/casey/just)) driving `tool/build.sh`; CI via GitHub Actions |

---

## Project Structure

```
lib/
  main.dart                    ← app entry (runApp + root MaterialApp)
  build_info.dart              ← generated by tool/build.sh (version + timestamp); never hand-edit
  models/                      ← plain Dart data classes + JSON (de)serialization
  data/                        ← repositories, API clients, storage wrappers, platform-source wrappers
  ui/                          ← screen widgets (one screen per file, PascalCase)
test/                          ← widget + unit tests, file names end in _test.dart
tool/
  build.sh                     ← stamps build_info.dart, runs `flutter build <target> --release`
  push-to-phone.sh             ← optional: deliver release APK to a device
android/  ios/  windows/  macos/  linux/  web/   ← platform folders, only those actually targeted
```

- `lib/data/` files are the **only** layer that touches networking, storage, or platform plugins. Widgets in `lib/ui/` must go through a repository/source class.
- `lib/models/` holds pure Dart — no Flutter imports, no I/O.
- One widget per file; file name matches the public class (`snake_case.dart` for the file, `PascalCase` for the class).

---

## Dart / Flutter Conventions

- Target the latest stable Flutter; pin the Dart SDK constraint in `pubspec.yaml` (e.g. `sdk: ^3.6.2`)
- `const` constructors and `const` literals everywhere they apply — let the analyzer guide you
- Prefer `final` over `var`; avoid `dynamic` outside JSON boundaries
- Material 3 only (`useMaterial3: true`) — do not mix Material 2 / Material 3 widgets
- One root `MaterialApp` in `main.dart`; theme + `darkTheme` driven by a single `colorSchemeSeed`
- Never call `setState` after `dispose` — guard async callbacks with `if (!mounted) return;`
- Cancel `StreamSubscription`s and dispose `TextEditingController` / `FocusNode` / `AnimationController` in `dispose()`
- Use `late final` for fields initialized once from `widget.*` in `State` (the standard pattern for injectable defaults)
- No `print` in committed code — use `debugPrint` if a log statement is genuinely needed, otherwise delete it (`avoid_print` lint must stay on)

---

## State Management

The default is **the simplest thing that works**:

| Scope | Pick |
|---|---|
| Widget-local UI state (form fields, toggles, loading flags) | `StatefulWidget` + `setState` |
| Dependencies a screen needs (repos, sources, storage) | Constructor injection with optional params + sensible defaults — see pattern below |
| Cross-tree state (auth, theme, current user) | `provider` (`ChangeNotifierProvider` / `Provider.of` / `Consumer`) |
| Anything more complex | Discuss before introducing BLoC / Riverpod / GetX — do not add silently |

### Constructor injection pattern (testability without DI framework)

Production widgets accept their collaborators as **optional** constructor parameters with sane defaults. Tests pass fakes; production passes nothing.

```dart
class HomePage extends StatefulWidget {
  final SecureStorage? storage;
  final VikunjaRepository? repository;

  const HomePage({super.key, this.storage, this.repository});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SecureStorage _storage = widget.storage ?? SecureStorage();
  late final VikunjaRepository _repository =
      widget.repository ?? VikunjaRepository(VikunjaApi(_storage));
  // ...
}
```

This is the agreed in-house pattern. Do not replace it with `get_it`, `injectable`, or service-locator code without asking.

### Wrapping platform plugins for testability

Plugins that read from the OS (share intents, file pickers, biometrics, deep links) must be wrapped behind a small abstract interface in `lib/data/` so widget tests can inject a fake.

```dart
abstract class ShareIntentSource {
  Stream<List<SharedMediaFile>> getMediaStream();
  Future<List<SharedMediaFile>> getInitialMedia();
  void reset();
}

class DefaultShareIntentSource implements ShareIntentSource {
  const DefaultShareIntentSource();
  @override Stream<List<SharedMediaFile>> getMediaStream() =>
      ReceiveSharingIntent.instance.getMediaStream();
  // ...
}
```

---

## Routing & Navigation

- Default to imperative `Navigator` + `MaterialPageRoute` — minimal ceremony, easy to test.
- Use `pushReplacement` when the previous screen should be discarded (e.g. picker → confirmation).
- Use `pushAndRemoveUntil((route) => route.isFirst, ...)` when a re-entry from outside (share intent, deep link) lands the user mid-stack and you must collapse stale screens.
- Never call navigation from inside `build()`; only from event handlers / `initState` / async callbacks (after `mounted` check).
- Reach for `go_router` only when you need URL-driven deep links, web routing, or nested ShellRoute navigation. State the reason in the PR.

---

## Networking & Data Layer

- All HTTP via `package:http`. The API client takes an `http.Client` constructor parameter so tests can inject a fake.
- API client returns typed models; widgets never see raw `Response` objects.
- A `Repository` sits between API and UI for any logic that combines calls (pagination loops, filtering, retries).
- Errors: throw a typed exception from the API/repo; handle in the widget (`try`/`catch`) and surface via `setState(() => _error = '...')` or a `SnackBar`. Never swallow.
- Always `.timeout(...)` on network calls that can hang (title fetches, third-party endpoints).

```dart
class VikunjaApi {
  final http.Client _client;
  VikunjaApi(this._storage, {http.Client? client}) : _client = client ?? http.Client();
  // ...
}
```

---

## Storage

| Use case | Tool |
|---|---|
| API tokens, credentials, anything sensitive | `flutter_secure_storage` |
| Settings, recents, history, non-sensitive small JSON | `shared_preferences` |
| Larger structured data | SQLite via `sqflite` (or `drift`) — only if `shared_preferences` is the wrong shape; ask before introducing |
| Files | `path_provider` for the right OS-specific dir |

- Wrap each storage backend in a small class in `lib/data/` (e.g. `SecureStorage`, `TaskHistory`) — widgets never call the plugin directly.
- Never log or display token/credential values, even on debug.

---

## Testing

### Layout

```
test/
  <feature>_test.dart          ← widget tests for screens + flows
  <module>_unit_test.dart      ← pure-Dart unit tests for repositories, parsers, models
```

Test files mirror the production tree where useful. Keep them flat and discoverable.

### Conventions

- `flutter_test` only by default. **Do not add `mockito`, `mocktail`, `build_runner`, or codegen-based mocking without asking** — write hand-rolled fakes that extend or implement the production class.
- Inject fakes through the optional constructor params of the widget under test.
- For `shared_preferences`-backed code, call `SharedPreferences.setMockInitialValues({})` in `setUp`.
- For `flutter_secure_storage` use a fake subclass overriding `instanceUrl` / `apiToken` / `isConfigured` — there is no first-party in-memory backend.
- Use `pumpAndSettle` after async work; for tight async loops a small explicit duration (`pumpAndSettle(const Duration(milliseconds: 100))`) is fine.
- Always `addTearDown(...)` for `StreamController` / disposable test fakes.
- Test naming: describe the behaviour in plain English (`'records the new task in local history after Done'`). The base instruction's `MethodName_StateUnderTest_ExpectedBehavior` pattern is fine for pure-Dart unit tests; widget tests read better as sentences.

### Sample widget test skeleton

```dart
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('redirects share to setup screen when not configured', (tester) async {
    final shareSource = _FakeShareIntentSource();
    addTearDown(shareSource.dispose);

    await tester.pumpWidget(MaterialApp(
      home: HomePage(
        storage: _UnconfiguredSecureStorage(),
        shareSource: shareSource,
        enableShareListener: true,
      ),
    ));
    await tester.pumpAndSettle();

    shareSource.fireTextShare('https://example.com/page');
    await tester.pumpAndSettle();

    expect(find.byType(ProjectPickerScreen), findsNothing);
  });
}
```

### Required after every change

- `flutter analyze` passes with zero issues
- `flutter test` passes the **full** suite — not just the new test
- Never modify a test to make it green. Never hardcode return values, mock results, or stub logic to satisfy a test. Never silently swallow exceptions.

---

## UI workflow — stack-specific hints

Phase order and gates are defined in `base-instructions.md`. For Flutter:

- **Phase 1 (wireframe):** think in Material 3 regions — `Scaffold`, `AppBar`, `Drawer`/`NavigationBar`, `ListView`, `TextField`, `FilledButton`, `Chip`, `SnackBar`, `Dialog`, `BottomSheet`.
- **Phase 2 (flow):** map screens to widget classes, named with the file (`SetupScreen`, `ProjectPickerScreen`); identify which collaborators each one needs in its constructor.
- **Phase 3 (build):** shell first (Scaffold + AppBar + empty body), then widget tree, then async/state, then polish (loading skeletons, error text, empty states). Use `CircularProgressIndicator` for loading, `SnackBar` for transient feedback, error text styled with `Theme.of(context).colorScheme.error`.
- **Phase 4 (review):** const-correct, no `setState` after `dispose`, all controllers disposed, all `mounted` checks in place, a widget test exists for the screen's primary flow, no raw `print`.

---

## Localization & Regional Formatting

Base rules for language support and regional formatting live in `base-instructions.md`. For this stack:

- Add `flutter_localizations` (SDK) and `intl` to `pubspec.yaml`. Generate ARB-driven message classes via `flutter gen-l10n` — `l10n.yaml` configured for `lib/l10n/app_en.arb` and `app_de.arb`.
- `MaterialApp` configuration:
  ```dart
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: const [
      Locale('en'),
      Locale('de', 'CH'),
      Locale('de', 'DE'),
      Locale('de', 'AT'),
    ],
    localeResolutionCallback: (deviceLocale, supported) {
      if (deviceLocale?.languageCode == 'de') {
        return supported.firstWhere(
          (l) => l.languageCode == 'de'
              && l.countryCode == deviceLocale!.countryCode,
          orElse: () => const Locale('de', 'CH'), // fallback for unrecognized de-*
        );
      }
      return const Locale('en');
    },
    locale: _userOverride, // null = follow OS
    // ...
  );
  ```
- Persist the user's language override in `shared_preferences` (key: `app.locale`); `null` means follow OS.
- Format dates with `DateFormat.yMd(locale.toLanguageTag())`, numbers with `NumberFormat.decimalPattern(locale.toLanguageTag())`, currency with `NumberFormat.simpleCurrency(locale: locale.toLanguageTag())`.
- Never call `.toString()` on `DateTime` / `num` for user-visible text — always go through `intl`.
- All user-visible strings come from `AppLocalizations.of(context)` — no string literals in widget trees.

---

## Essential Commands

```bash
# First-time / after pubspec change
flutter pub get
flutter pub upgrade --major-versions   # ask before bumping majors

# Run / develop
flutter run                            # connected device or default
flutter run -d windows                 # specific device
flutter run --release                  # release-mode locally

# Static checks
flutter analyze                        # MUST pass before commit
dart format --set-exit-if-changed lib test   # CI gate

# Tests
flutter test                           # full suite
flutter test test/<file>_test.dart     # single file
flutter test --coverage                # writes coverage/lcov.info

# Builds (always via the project justfile so build_info.dart is stamped)
just apk                               # release APK → build/app/outputs/flutter-apk/app-release.apk
just windows                           # release Windows build
flutter build appbundle --release      # Play Store AAB (when shipping to Play)
flutter build ios --release            # iOS, requires macOS + Xcode
flutter build web --release            # web

# Housekeeping
flutter clean                          # nuke build/, regen on next run
flutter pub outdated                   # see what's behind
```

**Do not bypass `tool/build.sh`** for release builds. It writes `lib/build_info.dart` (version + UTC timestamp) which the app surfaces in the UI. Calling `flutter build apk` directly leaves `build_info.dart` stale.

---

## Platform-Specific Notes

### Android

- Manifest at `android/app/src/main/AndroidManifest.xml`. Add `<uses-permission>` only when needed; `INTERNET` is enough for an HTTP-only app.
- Share-target intent filters live on `MainActivity` (`android.intent.action.SEND` / `SEND_MULTIPLE`).
- `applicationId` and `namespace` in `android/app/build.gradle`/`build.gradle.kts` use reverse-DNS (`ch.freaxnx01.<app>`).
- `compileOptions` and `kotlinOptions` target Java/Kotlin 17.
- Release signing: **never commit a keystore or `key.properties`**. Reference them via env-driven Gradle properties; default to debug-signed in dev as the scaffolded `buildTypes.release` does.
- `minSdk` / `targetSdk` come from `flutter.*` — do not hand-pin unless a plugin requires it.

### iOS

- Bundle ID set in Xcode (`Runner.xcodeproj`); keep it in sync with the Android `applicationId`.
- Permissions go in `ios/Runner/Info.plist` with `NSCameraUsageDescription`, etc. — every entry needs a human-readable purpose string or App Store review will reject.
- Dart-side code targets iOS through the same code path; only branch on `Platform.isIOS` / `defaultTargetPlatform == TargetPlatform.iOS` when behaviour genuinely differs.
- Building for iOS requires macOS + Xcode + a CocoaPods install (`cd ios && pod install`) after adding/upgrading plugins.

### Desktop (Windows / macOS / Linux)

- Confirm desktop support is enabled (`flutter config --enable-windows-desktop`, etc.) and the platform folder is committed.
- Some plugins are mobile-only — guard their use behind a platform check, e.g.:
  ```dart
  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  ```
- Window size, title, and min size are configured in `windows/runner/main.cpp` and `linux/my_application.cc`.

### Web

- Only enable web support when actually shipping a web build — it adds wasm/JS interop pitfalls (no `dart:io`, `flutter_secure_storage` falls back to localStorage, etc.).
- `flutter build web --release` outputs to `build/web/`. Serve with proper cache headers.

---

## Key Dependencies (defaults — discuss before swapping)

| Package | Purpose | Notes |
|---|---|---|
| `http` | HTTP client | Inject the `Client` for testability |
| `html` | HTML parsing | Used for page-title resolution |
| `flutter_secure_storage` | Tokens / credentials | Wrap in a `SecureStorage` class |
| `shared_preferences` | Non-sensitive small KV | Wrap per-feature (e.g. `TaskHistory`) |
| `provider` | Cross-tree state | Only when `setState` + constructor injection is not enough |
| `receive_sharing_intent` | Android/iOS share target | Always wrap behind an injectable `ShareIntentSource` |
| `flutter_lints` (dev) | Default Flutter lint rule set | Keep all defaults on |
| `flutter_test` (dev) | Widget + unit testing | First-party only; no codegen mocks |

---

## Logging & Observability

- No `print` — `debugPrint` only when something genuinely useful in a debug session, otherwise delete.
- For real apps with crashes worth tracking: integrate Firebase Crashlytics or Sentry **only when the user asks**; do not add silently.
- Show errors in the UI (text + `Theme.of(context).colorScheme.error`, or a `SnackBar`) — do not silently swallow exceptions.

---

## Versioning (stack binding)

Base rules (SemVer, Conventional Commits → bump mapping, `git-cliff`) live in `base-instructions.md`. For this stack:

- The single source of version truth is `pubspec.yaml` `version: <MAJOR>.<MINOR>.<PATCH>+<build>`. Everything else (Android `versionCode`/`versionName`, iOS `CFBundleShortVersionString`) is derived from it via `flutter.*` Gradle and the Flutter iOS toolchain — do not hand-edit them.
- The build number suffix (`+<build>`) is what stores require to be monotonic; bump it on every store upload.
- `tool/build.sh` reads `version:` from `pubspec.yaml` and writes it (plus a UTC timestamp) into `lib/build_info.dart`, which the UI displays. Do not hand-edit `build_info.dart`.

---

## CI/CD (GitHub Actions outline)

Pipeline stages: `setup → analyze → test → build`.

```yaml
jobs:
  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: dart format --set-exit-if-changed lib test
      - run: flutter analyze
      - run: flutter test --coverage
      - run: ./tool/build.sh apk     # only on main / release tags
```

- iOS / macOS builds need `runs-on: macos-latest` and a separate job.
- Cache `~/.pub-cache` keyed on `pubspec.lock`.
- Run `flutter pub outdated` on a schedule to catch drift; do not auto-bump.

---

## Security

- Tokens and credentials live in `flutter_secure_storage` only — never in `shared_preferences`, never in source, never in logs
- HTTPS only; reject any setup flow that accepts a non-`https://` URL except when explicitly opting into LAN testing
- Validate user-supplied URLs before persisting (`SecureStorage._normalizeUrl` style: trim, strip trailing `/`, prepend `https://` if scheme missing)
- Never display token values in the UI — mask with `obscureText` and a visibility toggle that defaults to off
- For attachment uploads, never log raw file contents
- Run `flutter pub outdated` and review dependency changelogs before bumping; remove unused dependencies

---

## Project Scaffold Checklist (Flutter)

- [ ] `pubspec.yaml` with pinned Dart SDK constraint and explicit version
- [ ] `analysis_options.yaml` including `package:flutter_lints/flutter.yaml`
- [ ] `lib/{models,data,ui}/` folder structure
- [ ] `lib/build_info.dart` generated by `tool/build.sh` (gitignored if regenerated per build, otherwise committed with a placeholder)
- [ ] `justfile` exposing `apk`, `windows` (and other release recipes actually used), `clean`
- [ ] `tool/build.sh` that stamps `build_info.dart` and runs `flutter build`
- [ ] At least one `test/*_test.dart` covering the primary flow with hand-rolled fakes
- [ ] Platform folders only for platforms actually shipped (drop unused `ios/`, `web/`, etc.)
- [ ] `AndroidManifest.xml` with the minimum permissions needed
- [ ] `CHANGELOG.md` with `[Unreleased]` section
- [ ] `cliff.toml` for `git-cliff`
- [ ] `.gitignore` includes `build/`, `.dart_tool/`, `.flutter-plugins`, `.flutter-plugins-dependencies`, `*.iml`, `.idea/`, platform `Pods/`, signing material
- [ ] `.github/copilot-instructions.md`, `CLAUDE.md`, `SKILL.md` regenerated from base + this overlay
- [ ] GitHub Actions workflow (analyze + test + build)
- [ ] Branch protection on `main`

---

## Agent Guardrails (stack-specific additions)

In addition to the base guardrails:

- Do not add a pub package without asking — every `pubspec.yaml` change is a deliberate decision
- Do not change the Dart SDK constraint or the Flutter channel
- Do not introduce a new state-management library (Riverpod, BLoC, GetX, MobX, get_it, …) without explicit approval — `provider` + constructor injection is the default
- Do not introduce code generation (`build_runner`, `freezed`, `json_serializable`, `injectable`) without explicit approval
- Do not add a routing library (`go_router`, `auto_route`) until imperative `Navigator` is provably insufficient
- Do not edit `lib/build_info.dart` by hand — it is regenerated by `tool/build.sh`
- Do not bypass `tool/build.sh` for release builds
- Do not commit signing keystores, `key.properties`, `GoogleService-Info.plist` with prod secrets, or any token
- Do not enable a platform folder (`ios/`, `web/`, `macos/`, `linux/`) the project does not actually ship to
- Never call `setState` after `await` without a `mounted` check
- Never disable lints to silence warnings — fix the code

### Never generate (this stack)

- `print(...)` in committed code (use `debugPrint` only when genuinely useful, otherwise delete)
- `setState` calls after `await` without an `if (!mounted) return;` guard
- Direct plugin calls from widgets (always go through a wrapper in `lib/data/`)
- HTTP calls from widgets (always through an API client / repository)
- Hardcoded URLs, tokens, or credentials in source files
- Tests modified to pass — fix the implementation
- Hardcoded return values, fake results, or stub logic to satisfy a test
- Silently swallowed exceptions to make a test green
- `// ignore:` lint suppressions to fix build errors
- Commented-out code blocks — delete them, git has history
- `dynamic` outside JSON parsing boundaries
- Mixing Material 2 and Material 3 widgets in the same app
- Blocking calls in `build()` (no async, no I/O — only widget construction)
- Undisposed `TextEditingController` / `FocusNode` / `AnimationController` / `StreamSubscription`
