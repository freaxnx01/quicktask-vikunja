# Release Notes — Slash Command

Generate user-friendly release notes in RELEASENOTES.md from git history.

**Target:** $ARGUMENTS

---

## Purpose

RELEASENOTES.md is the **user-facing** companion to CHANGELOG.md. While CHANGELOG.md is auto-generated from Conventional Commits (developer-oriented), RELEASENOTES.md summarizes each version in plain English for end users and stakeholders.

---

## Steps

### Step 1 — Gather version info

- Read the current version from the project's version source (defined in the active stack overlay — e.g. `Directory.Build.props` for .NET, `pubspec.yaml` for Flutter, `package.json` for Node)
- List all git tags sorted by version: `git tag --sort=-v:refname`
- Read existing `RELEASENOTES.md` (if it exists) and identify which versions already have entries

### Step 2 — Identify missing versions

- Compare git tags against versions already documented in RELEASENOTES.md
- Only generate entries for **missing** versions — never modify or regenerate existing entries
- If arguments specify a version (e.g. `/release-notes v1.4.2`), only generate that version

### Step 3 — Collect commits for each missing version

For each missing version, get the commits between the previous tag and the version's tag:

```bash
# For v1.4.2 (previous tag is v1.4.1):
git log v1.4.1..v1.4.2 --oneline --no-merges
```

For the earliest tag with no predecessor, use:

```bash
git log v1.0.0 --oneline --no-merges
```

### Step 4 — Write user-friendly summaries

For each missing version, write a summary following these rules:

- **Language:** English
- **Audience:** End users, not developers — no commit hashes, no module prefixes, no technical jargon
- **Tone:** Professional, concise, friendly
- **Group by theme:** e.g. "New Features", "Improvements", "Bug Fixes" — but only include groups that have content
- **Summarize, don't list commits:** Combine related commits into single bullet points. "Fixed several issues with form validation" is better than listing 5 separate fix commits
- **Skip internal changes:** Omit chore, ci, refactor, docs, and test commits unless they have user-visible impact
- **Keep it short:** 3-8 bullet points per version is ideal

### Step 5 — Update RELEASENOTES.md

- If the file doesn't exist, create it with the header (see Format below)
- Insert new version entries **after the header and before existing entries** (latest version first)
- Never touch existing entries — append-only for new versions
- Write the file using the Edit tool (or Write if creating new)

### Step 6 — Verify

- Read back RELEASENOTES.md to confirm the new entries look correct
- Confirm that existing entries are unchanged
- Report what was added

---

## Format

```markdown
# Release Notes

User-friendly summary of changes in each version.

---

## Version X.Y.Z

_Released YYYY-MM-DD_

### New Features
- Description of user-visible feature

### Improvements
- Description of user-visible improvement

### Bug Fixes
- Description of user-visible fix

---
```

- Use `---` horizontal rules between versions for visual separation
- Get the release date from the git tag: `git log -1 --format=%ai v1.4.2 | cut -d' ' -f1`
- Omit empty groups (e.g. if no new features, don't include the "New Features" heading)

---

## Rules

- **Never modify existing entries** — only add new ones
- **Never include** commit hashes, PR numbers, or module prefixes in the output
- **Skip** commits typed as `chore`, `ci`, `refactor`, `test`, `docs` unless they have direct user impact
- **Combine** related commits into single, clear bullet points
- If there are no missing versions to generate, say so and stop
- Do not commit the changes — the user will review and commit separately
