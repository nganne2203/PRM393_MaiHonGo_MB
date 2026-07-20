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

Date: 2026-07-20
Owner: Codex implementation pass

- `flutter analyze`: passed, no issues found.
- `flutter test`: passed, 46 tests. Added coverage for randomized quiz options, complete offline package storage, package cleanup, bookmark queue retry, flashcard resume state, writing drafts, deduplicated sync operations, and retention when Wi-Fi is available but the backend is unreachable.
- Android `assembleDebug`: passed. Local notification receivers, timezone plugin, core library desugaring, and the Flutter application compiled into the debug APK.
- iOS Simulator build: not completed because Flutter could not finish downloading the iOS engine toolchain; no Xcode compile was reached.
- Manual Android/iOS scripts still need execution on physical or emulated devices before release sign-off.

## Current Bug Log

| ID | Feature | Severity | Owner | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| QA-001 | Google OAuth platform setup | High | Release owner | External setup | Android OAuth client/SHA and iOS client URL scheme must match the final application identifiers. |
| QA-002 | Release identity and signing | High | Release owner | External setup | Replace `com.example.maihongo_mb` and configure a production signing key before store release. |
| QA-003 | Device regression | Medium | QA | Pending | Execute clean install, notification permission, offline package, reconnect sync, recording, and iOS scripts. |

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
