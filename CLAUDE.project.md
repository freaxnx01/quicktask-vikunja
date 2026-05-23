# Project-Specific Conventions (QuickTask)

Agent context unique to this project. Survives `/init-instructions` regeneration — the assembled `CLAUDE.md` / `SKILL.md` / `.github/copilot-instructions.md` files reference this one by path.

## What this app is

QuickTask is a Flutter app whose primary purpose is to act as an **Android share target**: the user shares a URL, text, or file from another app and QuickTask creates a task in a self-hosted Vikunja instance. Desktop (Windows/Linux) supports manual entry only — share-intent flows are mobile-only.

## Architecture snapshot

`lib/main.dart` owns the share-intent listener (`receive_sharing_intent`) and the route stack: `RecentTasksScreen` (home) → `ProjectPickerScreen` (push) → `TaskConfirmationScreen` (pushReplacement). Data layer in `lib/data/` (Vikunja API client, secure storage for token, local task history & project-usage tracker via `shared_preferences`, HTML title fetcher). Models in `lib/models/`.

## Queued work

Open items not yet tracked as issues live in `TODO.md` at the repo root. At the start of a session with no specific task, pick the top unchecked item, implement it, open a PR, and check the box in the same PR.

## Autonomous-work conventions

- Branch naming: `claude/issue-<N>-<short-slug>`
- PR body must include `Closes #<N>` so the issue auto-closes on merge
- Stay scoped — if you spot unrelated work, mention it in the PR body, don't bundle it
- If unsure: comment the question on the issue, remove the `claude-working` label, exit. A human re-labels `claude-ready` once answered. Don't invent product/UX decisions.

## Things to be careful about

- **Share-intent activity lifecycle is the #1 bug source.** `MainActivity` is `singleTop` with `taskAffinity=""`. The route stack persists across multiple shares unless explicitly cleared. When in doubt, clear back to `RecentTasksScreen` between shares.
- **`getInitialMedia()` must be `reset()`'d** after handling, or it can replay on rebuild.
- **Vikunja token is in secure storage** — never log it, never write it to disk in plaintext, never include it in error messages or PR descriptions.
- **No telemetry, analytics, or crash reporting** — intentionally minimal, personal self-hosted instance only.

## Project-specific commands

- `just apk` → release APK at `build/app/outputs/flutter-apk/`
- `PHONE_IP=192.168.x.y` just push → send APK to phone via LocalSend

## Docs layout (project-specific)

`docs/superpowers/{specs,plans}/` — design docs / implementation plans (workflow convention, not covered by base).
