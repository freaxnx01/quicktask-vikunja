# TODO

Pending work queued for Claude to pick up in a future session. Ordered by priority.

## Bugs to fix

- [ ] **[#11](https://github.com/freaxnx01/quicktask-vikunja/issues/11) — `TitleFetcher.shortenUrl` returns empty string for unparseable input.** Labeled `claude-ready`; intended for the autonomous trigger but queued here in case the daily trigger limit is hit. Acceptance criteria are in the issue. Don't forget to update `test/data/title_fetcher_test.dart` to assert the new correct behavior and remove the "known defect" comment.

## Test quality follow-ups (from PR #12 review)

- [ ] Rename or split the misnamed test `vikunja_api_test.dart::'paginates until a partial batch is returned'`. Today it asserts `calls == 1` — the real pagination loop lives in `VikunjaRepository.getAllProjects` and is untested. Add a `test/data/vikunja_repository_test.dart` covering the loop-until-partial branch with a `MockClient`.
- [ ] Tighten the brittle query-string assertion in `vikunja_api_test.dart::'passes limit + sort filters in query string'`. Prefer `captured!.queryParametersAll['sort_by[]']` over raw `contains('sort_by%5B%5D=...')` so encoding details of the Dart SDK aren't locked in.
- [ ] `createTask` error-path test only covers 500. Add a 4xx case (e.g. 422 validation) — one extra `expect` closes the gap.
- [ ] `project_picker_screen_test.dart::'non-recent projects are sorted alphabetically'` never seeds `_recentIds`. The `_recentProjects` section ordering is still untested — add a test that seeds recents and asserts their order.
- [ ] Consider extracting a `SecureStorage` abstract interface in a follow-up. Today the test fakes extend the concrete class, which instantiates `FlutterSecureStorage` in the parent field initializer — inert now, but if `SecureStorage` ever gains eager side effects, all tests would break mysteriously.

## CLAUDE.md follow-ups (from PR #8 review)

- [ ] `make push PHONE_IP=...` example in `CLAUDE.md` is misleading — the `Makefile` doesn't consume `PHONE_IP` as a make variable; `tool/push-to-phone.sh` handles it. Either document the env-var contract the script actually expects, or drop `PHONE_IP=` from the example.
- [ ] Add one line to `CLAUDE.md` on local dev setup: where does the agent get a Vikunja base URL / API token to exercise `SetupScreen` or run integration-style tests? (e.g. "Run a throwaway Vikunja via docker-compose, or ask the maintainer for a dev token.") Without this a 6-month-later agent is stuck.
- [ ] Mention `lib/data/vikunja_repository.dart` in the data-layer description (currently lists API client / storage / history / title fetcher but not the repository wrapper).
- [ ] Note that `provider: ^6.1.2` is in `pubspec.yaml` but not wired anywhere yet — so agents don't assume DI exists.

## Stack-fix follow-ups (from PR #9 review)

- [ ] Add a short comment in `lib/main.dart::_navigateToProjectPicker` explaining that the `navigator` captured in the `onDone` closure assumes a single root `Navigator` (true today from `MaterialApp`, but fragile if a nested `Navigator` is ever introduced).
- [ ] Document that `_shareEnabled` is read once via `late final`, so `enableShareListener` can't be toggled at runtime (tests pass it once; that's the intent).

## Process instructions for the next session

- Prefer to open one PR per checklist item (keeps review diffs small and revertable).
- Always run `flutter analyze` and `flutter test` before pushing.
- Branch naming: `claude/<slug>` for small chores, `claude/issue-N-<slug>` when fixing a numbered issue.
- Close this TODO item by checking the box and committing — do not delete the line, so history is preserved.
