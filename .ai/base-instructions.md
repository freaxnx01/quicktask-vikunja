# AI Agent Base Instructions

Canonical, **stack-agnostic** reference for all AI coding agents. Applies to every project regardless of language or framework. Stack-specific overlays live in `.ai/stacks/<stack>.md` and are loaded alongside this file.

Tool-specific files (`CLAUDE.md`, `.github/copilot-instructions.md`, `SKILL.md`) derive from this file plus the chosen stack overlay.

---

## How this file composes

```
.ai/
  base-instructions.md        ← you are here (stack-agnostic)
  stacks/
    dotnet.md                 ← .NET / ASP.NET Core / Blazor
    <other>.md                ← added as new stacks are adopted
  skills/
    commit.md · push.md · release-notes.md
    ui-brainstorm.md · ui-flow.md · ui-build.md · ui-review.md
    init-instructions.md
```

A project loads **base + exactly one stack overlay**. Agents never need to see stacks they are not working in.

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

## Versioning (SemVer)

All projects follow [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH  →  e.g. 2.4.1
```

| Increment | When |
|---|---|
| `MAJOR` | Breaking change — incompatible API or behaviour change |
| `MINOR` | New functionality, backwards-compatible |
| `PATCH` | Bug fix, backwards-compatible |

**Mapping from Conventional Commits:**

| Commit type | Version bump |
|---|---|
| `BREAKING CHANGE:` footer or `!` after type | MAJOR |
| `feat` | MINOR |
| `fix`, `perf` | PATCH |
| `chore`, `docs`, `ci`, `test`, `refactor` | no bump |

- Git tags follow `v<MAJOR>.<MINOR>.<PATCH>` (e.g. `v1.3.0`) — tag on `main` after merge
- Pre-release: `v1.0.0-alpha.1`, `v1.0.0-beta.2`, `v1.0.0-rc.1`
- **git-cliff** is the changelog and release notes tool — configured via `cliff.toml`
- Where the version is declared in the project (build file, manifest, etc.) is defined by the stack overlay — but it must be declared in **exactly one place**

---

## Changelog

All projects maintain a `CHANGELOG.md` in the repo root following [Keep a Changelog](https://keepachangelog.com) conventions.

```markdown
# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-06-01
### Added
- Order cancellation endpoint

### Fixed
- Token refresh edge case on expiry boundary

## [1.0.0] - 2025-04-15
### Added
- Initial release
```

**Sections per release:** `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`

- `[Unreleased]` section accumulates changes until a release is cut
- Auto-generation: **git-cliff** with `cliff.toml` configured for Conventional Commits
- CI integration: `orhun/git-cliff-action` in GitHub Actions generates release notes into GitHub Releases
- CI can validate that `[Unreleased]` is not empty before allowing a release branch

---

## 12-Factor App Compliance

Projects follow the [12-Factor App](https://www.12factor.net/) methodology. Each factor stated neutrally:

| Factor | Rule |
|---|---|
| **I. Codebase** | One repo per service/app, tracked in Git |
| **II. Dependencies** | All declared in the project's manifest/lockfile; nothing assumed from the environment |
| **III. Config** | All environment-specific config via environment variables — nothing per-environment baked into config files |
| **IV. Backing services** | DB, cache, message broker treated as attached resources via connection-string env vars |
| **V. Build, release, run** | Multi-stage container build: build image ≠ run image. Never build inside a running container |
| **VI. Processes** | Stateless processes — no sticky sessions, no local file state |
| **VII. Port binding** | App is self-contained; exports HTTP on a configurable port |
| **VIII. Concurrency** | Scale via multiple container replicas, not threads |
| **IX. Disposability** | Fast startup, graceful shutdown on SIGTERM |
| **X. Dev/prod parity** | Local override files mirror prod config as closely as possible |
| **XI. Logs** | Treat logs as event streams — write to stdout, never to files in a container |
| **XII. Admin processes** | Migrations and seed scripts run as one-off commands, not baked into app startup |

Stack-specific enforcement details (e.g. which logging library, how migrations are wired) live in the stack overlay.

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

```markdown
## Summary
<!-- What does this PR do and why? -->

## Changes
-
-

## Testing
- [ ] Unit tests added/updated
- [ ] Component/integration tests added if applicable
- [ ] E2E test added/updated if user-facing flow changed
- [ ] Tested locally

## Checklist
- [ ] Tests pass
- [ ] No new vulnerable dependencies
- [ ] No secrets committed
- [ ] Migrations included if schema changed
- [ ] API/OpenAPI spec still valid (if applicable)
```

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

```
docs/
├── design/                    ← UI wireframes & Mermaid flows per feature
│   └── <feature-name>/
│       ├── wireframe.md       ← Phase 1 output (ASCII wireframe)
│       └── flow.md            ← Phase 2 output (Mermaid diagrams)
├── adr/                       ← Architecture Decision Records
└── ai-notes/                  ← AI agent working notes
```

- `README.md` and `CHANGELOG.md` live in the repo root
- UI design artifacts are saved per feature during the UI workflow phases
- AI agents write working notes to `docs/ai-notes/`, not `.ai/`
- `.ai/` is reserved for agent instructions and skill files only

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

Every new project, regardless of stack:

- [ ] `README.md` with setup + run commands
- [ ] `CHANGELOG.md` with `[Unreleased]` section
- [ ] `cliff.toml` for `git-cliff`
- [ ] `.gitignore` appropriate to the stack
- [ ] `CLAUDE.md` and `.github/copilot-instructions.md` generated from base + chosen stack overlay
- [ ] `/health/live` and `/health/ready` endpoints wired (or stack equivalent)
- [ ] CI workflow (build + test + security scan)
- [ ] Branch protection on `main`

Stack-specific additions (e.g. `Directory.Build.props`, `pubspec.yaml`, `package.json`) live in the stack overlay's scaffold checklist.
