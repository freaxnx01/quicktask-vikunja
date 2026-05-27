# Project Overview — QuickTask Vikunja

**Name:** `quicktask-vikunja`
**Purpose:** Android share-target app for quickly adding tasks to a self-hosted Vikunja instance.
**Status:** Active personal-use development. Single user (the developer). No public release.

## Stakeholders

Personal-use only — the developer is the sole user and stakeholder. There is no PM, no end-user feedback loop, no support burden. Decisions are made by the developer alone, optimized for the developer's own workflow.

Intentionally no telemetry, no analytics, no crash reporting — the app talks only to a single self-hosted Vikunja instance.

## Vision

Friction-free task capture from Android into a personal Vikunja instance. When the user encounters something worth saving — a URL, a snippet of text, a file — they share it from any Android app and one or two taps later it's a task in the right Vikunja project, with the URL's page title resolved automatically as the task title.

Desktop (Windows/Linux) is a manual-entry fallback for the same Vikunja instance — same UI, no share-intent path.

## Core customer need

"I find an interesting URL/text/file on my phone and want to save it as a task in my self-hosted Vikunja instance without copy-paste gymnastics, without opening Vikunja's mobile web UI, and without losing context to the sharing app I came from."

The implicit constraints behind this need:
- It has to be **fast** — a slow share-target loses to "I'll do it later" (and "later" never comes).
- It has to **resolve URL titles automatically** — pasting a raw URL as a task title is unhelpful.
- It has to **remember recent projects** — drilling into a project list every time is friction.
- It has to **not leak the API token** anywhere — secure storage only, never logs, never plaintext.

## Key features

- **Android share target.** Receives `ACTION_SEND` (text, single file) and `ACTION_SEND_MULTIPLE` (multiple files) intents.
- **URL title resolution.** For shared URLs, fetches the page's HTML `<title>` (5s timeout); falls back to the raw URL if unavailable. Honours `EXTRA_SUBJECT` from the sharing app when present.
- **Project picker.** Recents-first, favourites, then alphabetical. Project-usage tracker remembers last-used timestamps.
- **Recent tasks history.** Last 20 created tasks shown on the home screen; the screen also serves as the manual-entry entry point.
- **Vikunja REST API integration.** GET projects (paginated), PUT task, PUT attachments. Token stored via `flutter_secure_storage`.
- **Manual entry on desktop.** Windows/Linux builds skip the share-intent listener; same UI for editing the title and picking a project.
- **No telemetry.** Intentionally minimal; personal self-hosted instance only.

## Architecture (one paragraph)

Single-binary Flutter app. `lib/main.dart` owns the share-intent listener (`receive_sharing_intent` plugin) and the route stack `RecentTasksScreen → ProjectPickerScreen → TaskConfirmationScreen`. All I/O lives under `lib/data/` (Vikunja API client, secure storage, history, project-usage tracker, HTML title fetcher); widgets never call plugins directly. Models in `lib/models/` are pure Dart, no Flutter, no I/O — testable without a Flutter environment. Android `MainActivity` is `singleTop` with `taskAffinity=""` so multiple shares don't stack new task instances on top of each other. For full architecture detail see [`ARCHITECTURE.md`](ARCHITECTURE.md).
