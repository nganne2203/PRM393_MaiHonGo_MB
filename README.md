# MaiHonGo Mobile

MaiHonGo is a Flutter application for learning Japanese vocabulary through
lessons, flashcards, quizzes, listening, speaking, and writing practice. The
mobile client uses a REST API when online and SQLite-backed local storage for
downloaded content and pending synchronization work.

## Architecture

The project uses a pragmatic feature-first layered architecture:

```text
Screens and widgets
        |
Riverpod controllers / feature controllers
        |
Repositories
   |          |
REST API   SQLite / secure storage / preferences
```

- Presentation: `lib/screens`, `lib/features/*/screens`, and shared widgets.
- State and business flow: `lib/features/*/state` and `lib/core/sync`.
- Data access: `lib/features/*/repositories` and `lib/core/network`.
- Offline storage: `lib/core/storage` with SQLite.
- Authentication tokens: `flutter_secure_storage`.
- User preferences: `shared_preferences`.

## Main Features

- Email/password and Google authentication with JWT session restoration.
- Dashboard, lessons, vocabulary search, bookmarks, and progress.
- Flashcards with resume state and quiz submission/history.
- Downloadable offline lesson packages and retryable synchronization.
- Listening practice with cached audio and playback speed controls.
- Speaking recording, multipart upload, AI evaluation, and history.
- Writing drafts, submission, AI feedback, and history.
- Theme, study goals, reminders, sound preferences, and privacy controls.

## Local Setup

1. Start the backend on port `8080`.
2. Create `.env` from the team configuration:

```dotenv
API_BASE_URL=http://127.0.0.1:8080
GOOGLE_WEB_CLIENT_ID=<google-web-oauth-client-id>
```

3. Install dependencies and run the app:

```bash
flutter pub get
flutter run
```

For an Android emulator using the loopback URL, forward the API port:

```bash
adb reverse tcp:8080 tcp:8080
```

## Quality Checks

```bash
flutter analyze
flutter test
```

The test suite contains unit tests for models, repositories, quiz business
rules, SQLite, offline queues, and state transitions. Widget tests validate
shared UI states and responsive flashcard behavior.

## Release Build

Create an installable coursework/demo APK:

```bash
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For production upload signing, copy `android/key.properties.example` to
`android/key.properties`, create the referenced keystore under `android/app`,
and replace all placeholder secrets. Both files are ignored by Git. When
`key.properties` is absent, release builds use the debug key so every team
member can reproduce the classroom demo APK.

The final Android application ID and OAuth Android client must be changed
together. The current development package is `com.example.maihongo_mb`.

## Project Documents

- `docs/PRM393_TECHNICAL_REPORT.md`: report aligned with the course rubric.
- `docs/requirement_compliance_report.md`: requirement-to-evidence matrix.
- `docs/mobile_code_review_guide_vi.md`: UI-to-API and offline flow guide.
- `docs/qa/manual_qa_scripts.md`: manual demonstration scripts.
- `docs/offline_sqlite_storage.md`: local database design.
