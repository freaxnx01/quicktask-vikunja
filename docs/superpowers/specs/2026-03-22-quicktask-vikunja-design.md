# QuickTask for Vikunja — Design Spec

## Overview

Android app (Kotlin + Jetpack Compose) that acts as a share target for adding tasks to a self-hosted Vikunja instance. Optimized for the flow: browse → share → pick project → done.

## Core Use Case

User is in a browser with a URL open. They tap Share → select QuickTask → see a project picker → tap a project → task is created → app closes with a confirmation snackbar.

## Architecture

Single-module Android app. Two entry points, shared data layer.

```
ShareActivity (share intent)
    └─ ProjectPickerScreen
         └─ VikunjaRepository → VikunjaApiService (Retrofit)

MainActivity (launcher)
    └─ SetupScreen / RecentTasksScreen
         └─ VikunjaRepository → VikunjaApiService (Retrofit)
```

### Components

- **MainActivity** — launcher entry. First run: setup screen. After setup: recent tasks list.
- **ShareActivity** — share target for `text/plain`. Receives shared content, resolves task name, shows project picker, creates task.
- **VikunjaApiService** — Retrofit interface for Vikunja REST API.
- **VikunjaRepository** — thin layer over API. Caches project list in memory for the session.
- **TitleFetcher** — OkHttp GET + Jsoup `<title>` parsing. Jsoup handles edge cases (multiline, attributes, encoding) reliably at ~400KB.
- **SecureStorage** — `EncryptedSharedPreferences` for API token and instance URL.
- **TaskHistory** — SharedPreferences-backed list of last ~20 created tasks (name, project, timestamp).

## API Integration

**Authentication:** API token passed as `Authorization: Bearer <token>` header on all requests.

**Endpoints used:**
- `GET /api/v1/projects?per_page=1` — validate credentials on setup (doubles as endpoint check)
- `GET /api/v1/projects?per_page=100` — fetch all projects (paginate if >100 by following `page` param)
- `PUT /api/v1/projects/{id}/tasks` — create a task (body: `{ "title": "<task name>" }`)

**Note:** Verify exact HTTP methods and endpoints against the live instance's Swagger docs at `/api/v1/docs` before implementation.

## Data Flow

### Share Flow

1. User taps Share in browser → selects QuickTask
2. `ShareActivity` launches, reads `Intent.EXTRA_TEXT` and `Intent.EXTRA_SUBJECT`
3. If no credentials configured → redirect to SetupScreen with message
4. Content detection: regex check for URL pattern
5. **If URL:** Check `EXTRA_SUBJECT` first — if present, use as title directly. Otherwise `TitleFetcher` does GET request, parses `<title>` via Jsoup → task name = `"<title> - <url>"`; on failure → task name = raw URL
6. **If plain text:** task name = shared text as-is
7. Fetch projects from Vikunja API (paginate if needed)
8. Display project picker: recent projects first, then remaining A-Z
9. User optionally filters by typing, then taps a project
10. PUT task to selected project
11. On success: Snackbar "Task added to {project name}" (LENGTH_SHORT), finish activity after ~1.5s delay
12. On failure: Snackbar with error message, activity stays open for retry
13. Store task in local history for RecentTasksScreen

### Setup Flow

1. First launch → SetupScreen with two fields: instance URL, API token
2. "Connect" button → `GET /api/v1/projects?per_page=1` to validate credentials
3. URL normalization: strip trailing slash, prepend `https://` if no scheme provided
3. On success: store credentials in EncryptedSharedPreferences, navigate to main screen
4. On failure: show error message

### Project Ordering

- Track project usage with timestamps in SharedPreferences (map of projectId → lastUsedTimestamp)
- Top section ("Recent"): last 5 projects used, sorted most recent first
- Bottom section ("All Projects"): remaining projects sorted alphabetically
- Search/filter applies across both sections

## UI Screens

### ProjectPickerScreen (ShareActivity)

- Top: search/filter text field, auto-focused
- List with two sections:
  - "Recent" header → last ~5 used projects
  - "All Projects" header → remaining projects A-Z
- Tapping a project immediately creates the task (no confirmation)
- Loading spinner while fetching projects / creating task
- Material 3 design

### SetupScreen

- Instance URL text field (e.g. `https://vikunja.home.freaxnx01.ch`)
- API token field (password-masked, show/hide toggle)
- "Connect" button
- Error state for failed validation

### RecentTasksScreen

- List of recently added tasks (task name, project name, relative timestamp)
- Last ~20 entries, stored locally
- Settings gear icon in top bar → navigates to SetupScreen for editing credentials
- Empty state: "No tasks yet. Share a URL or text from another app to get started."

## Technical Decisions

- **Min SDK:** 26 (Android 8.0) — covers 95%+ of devices
- **Networking:** Retrofit + OkHttp + kotlinx.serialization + Jsoup (HTML title parsing)
- **DI:** Hilt
- **No Room database** — SharedPreferences is sufficient for task history and project usage tracking
- **No offline queue** — user is online when sharing from browser
- **Title fetch timeout:** 5 seconds, then fall back to raw URL

## Share Target Configuration

```xml
<activity android:name=".ShareActivity"
    android:exported="true"
    android:theme="@style/Theme.QuickTask.Transparent">
    <intent-filter>
        <action android:name="android.intent.action.SEND" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="text/plain" />
    </intent-filter>
</activity>
```

## App Identity

- **Name:** QuickTask for Vikunja
- **Package:** `ch.freaxnx01.quicktask.vikunja`
- **Repo:** `quicktask-vikunja`
