# Agent Notes — QuickTask Vikunja

Project-specific agent-facing context: operational gotchas, project-specific
commands, and repo-local workflow conventions. Read alongside the regenerated
`CLAUDE.md` (which carries the stack-agnostic + Flutter-specific conventions).

For strategic context (what the app is, why it exists), see
[`PROJECT-OVERVIEW.md`](PROJECT-OVERVIEW.md). For detailed architecture, see
[`ARCHITECTURE.md`](ARCHITECTURE.md).

## Things to be careful about

- **Share-intent activity lifecycle is the #1 bug source.** `MainActivity` is
  `singleTop` with `taskAffinity=""`. The route stack persists across multiple
  shares unless explicitly cleared. When in doubt, clear back to
  `RecentTasksScreen` between shares.
- **`getInitialMedia()` must be `reset()`'d** after handling, or it can replay
  on rebuild.
- **Vikunja token is in secure storage** — never log it, never write it to
  disk in plaintext, never include it in error messages or PR descriptions.
- **No telemetry, analytics, or crash reporting** — intentionally minimal,
  personal self-hosted instance only.

## Project-specific commands

- `just apk` → release APK at `build/app/outputs/flutter-apk/`
- `PHONE_IP=192.168.x.y just push` → send APK to phone via LocalSend

## Repo-local workflow conventions

### Queued work

Open items not yet tracked as issues live in `TODO.md` at the repo root. At
the start of a session with no specific task, pick the top unchecked item,
implement it, open a PR, and check the box in the same PR.

### Autonomous-work conventions

- Branch naming: `claude/issue-<N>-<short-slug>`
- PR body must include `Closes #<N>` so the issue auto-closes on merge
- Stay scoped — if you spot unrelated work, mention it in the PR body, don't
  bundle it
- If unsure: comment the question on the issue, remove the `claude-working`
  label, exit. A human re-labels `claude-ready` once answered. Don't invent
  product/UX decisions.

### Docs layout (project-specific)

- `docs/superpowers/{specs,plans}/` — design docs / implementation plans
  (workflow convention, not covered by base).
