# Sprint Regression and Bug Triage

Owner: Member 5

## Regression Pass

- Confirm the app starts from a clean install.
- Run auth, settings, bookmarks, offline, and practice QA scripts.
- Run smoke checks on Android emulator or Flutter web.
- Confirm all shared loading, error, empty, and offline states fit on mobile width.
- Confirm no screen depends on hardcoded demo data unless explicitly marked as fallback/demo.
- Run `flutter analyze`.
- Run `flutter test`.

## Latest Regression Run

Date: 2026-06-14
Owner: Member 5

- `flutter analyze`: passed, no issues found.
- `flutter test`: passed, all tests passed. Targeted Member 5 coverage includes shared state widgets, bookmark cache fallback, settings/onboarding persistence, and editable profile preferences.
- Known tooling warning: Flutter reports that `isar_flutter_libs` and `flutter_secure_storage` do not yet support Swift Package Manager for Apple targets. This is a dependency warning, not a current analyzer or test failure.

## Current Bug Log

| ID | Feature | Severity | Owner | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| None | Member 5 regression scope | N/A | Member 5 | Verified | No blocker, high, medium, or low defects were found in the automated regression run above. |

## Bug Triage Fields

Use these fields for sprint bug logging:

- Title
- Feature
- Environment
- Steps to reproduce
- Expected result
- Actual result
- Severity: blocker, high, medium, low
- Owner
- Status: new, assigned, fixed, verified, deferred
- Evidence: screenshot, log, test output, or screen recording

## Severity Guide

- Blocker: app cannot launch, login is impossible, data loss, or release cannot be tested.
- High: core flow broken for auth, lessons, bookmarks, offline, or practice submission.
- Medium: recoverable failure, confusing state, missing feedback, or inconsistent UI.
- Low: copy, spacing, minor visual polish, or non-blocking edge case.

## Sprint Closure Checklist

- All blocker and high bugs are fixed or explicitly deferred by the team.
- Acceptance criteria in `docs/qa/acceptance_criteria.md` are reviewed.
- Manual scripts in `docs/qa/manual_qa_scripts.md` are executed for changed areas.
- Test and analyzer results are recorded in the sprint handoff.
- Known backend dependencies and unavailable endpoints are listed before demo.
