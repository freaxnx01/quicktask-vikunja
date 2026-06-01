# Security Policy

QuickTask Vikunja is a personal-use Flutter app for capturing tasks into a
self-hosted Vikunja instance — see [`PROJECT-OVERVIEW.md`](PROJECT-OVERVIEW.md)
for context. There is no public release and no production deployment, but the
app handles an API token for a personal Vikunja instance, so security reports
are still welcome.

---

## Reporting a vulnerability

**Please do not open a public GitHub issue for security problems.**

Use GitHub's private vulnerability reporting instead:

- Open <https://github.com/freaxnx01/quicktask-vikunja/security/advisories/new>
  and file a private advisory.

Include as much of the following as you can:

- A short description of the issue and its impact
- Steps to reproduce (or a proof-of-concept)
- The affected version / commit SHA
- Any suggested fix or mitigation

You'll get an acknowledgement as soon as the report is seen. Because this is a
single-maintainer personal project there is no formal SLA, but reports are
read and acted on.

---

## Scope

In scope:

- The Flutter app source under `lib/` and `test/`
- The Android share-target integration and `MainActivity`
- Handling of the Vikunja API token in `flutter_secure_storage`
- The Vikunja REST client in `lib/data/`

Out of scope:

- Vulnerabilities in the upstream [Vikunja](https://vikunja.io/) server itself
  — report those to the Vikunja project directly
- Issues that require a rooted/jailbroken device or a malicious app already
  holding broad Android permissions
- Findings against forks or downstream redistributions

---

## Dependency scanning

Third-party Dart/Flutter dependencies declared in `pubspec.lock` are scanned
on every pull request and on every push to `main` by
[OSV-Scanner](https://google.github.io/osv-scanner/) — see
[`.github/workflows/vuln-scan.yml`](.github/workflows/vuln-scan.yml). The job
is a required status check on `main` and fails the build on any known
vulnerability, blocking auto-merge of a vulnerable bump.
