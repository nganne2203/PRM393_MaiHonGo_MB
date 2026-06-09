# MaiHonGo Flutter Gap Analysis and Team Plan

Date: 2026-06-09

Scope: analysis-only review of backend documentation, backend implementation, database schema, Flutter mobile app, React admin prototype, and the teacher's extended requirements for local data, offline learning, listening, speaking, and writing.

No feature implementation was performed.

## 1. Source Inventory

Reviewed sources:

- Backend docs: `MaiHongo_BE/docs/*.md`
- Backend source: `MaiHongo_BE/src/**`
- Backend API/OpenAPI source: `MaiHongo_BE/src/configs/swagger.ts`
- Backend database models: `MaiHongo_BE/src/models/*.ts`
- Flutter app: `MaiHonGo_MB/maihongo_mb/lib/**`
- Flutter dependencies: `MaiHonGo_MB/maihongo_mb/pubspec.yaml`
- React admin prototype: `MaiHonGo_FE/src/app/**`
- Teacher extension request: attached pasted text

Verification commands:

- `flutter analyze` in `MaiHonGo_MB/maihongo_mb`: passed, no issues.
- `flutter test` in `MaiHonGo_MB/maihongo_mb`: failed because `test/` directory is missing.
- `./node_modules/.bin/tsc --noEmit` in `MaiHongo_BE`: passed.

## 2. Executive Summary

The backend is a compact but mostly coherent REST API for the original vocabulary-learning scope: auth, lessons, vocabulary search, bookmarks, progress, quiz results, and dashboard summary exist. The Flutter app is a polished static prototype, not an integrated application. It has screens for the original flow, but it lacks a backend API layer, models matching backend data, repositories, scalable state management, local database usage, offline sync, test coverage, and implementation of the teacher's new listening, speaking, and writing requirements.

Major conclusion: do not rewrite the Flutter UI. Keep the current visual layer and introduce missing architecture below it: API client, DTO/model mapping, repositories, state management, Isar/local storage, sync queue, and then extend practice modules.

Highest-priority gaps:

1. Flutter has no HTTP/API dependency even though backend exposes JWT REST APIs.
2. Flutter has no `models`, `services/api`, `repositories`, `providers/bloc/controllers`, or local storage folders.
3. Flutter data is hardcoded in `lib/data/vocab_data.dart`.
4. Backend responses are wrapped as `{ success, message, data, pagination }`, while old markdown API examples show raw arrays/tokens.
5. Backend has no listening, speaking, writing, audio asset, recording, writing submission, or offline package/sync endpoints.
6. Offline is documented and partially represented by `isOfflineReady` in the lesson model, but no mobile local schema or sync code exists.
7. There are no Flutter tests.

## 3. Evidence Highlights

Documentation requirements:

- The SRS requires offline usage, downloaded lessons, and progress sync (`SOFTWARE_REQUIREMENT_SPECIFICATION.md:8-9`, `:30-32`, `:61-64`).
- The SRS defines auth, dashboard, flashcards, quiz, bookmarks, offline learning, and progress tracking (`SOFTWARE_REQUIREMENT_SPECIFICATION.md:36-68`).
- Local storage is expected to use MongoDB server side, Hive/SQLite locally, and SharedPreferences for flags (`SOFTWARE_REQUIREMENT_SPECIFICATION.md:85-86`).
- The offline guide says to cache lessons/vocabulary, store token/flags, and use a local queue with retry/backoff (`OFFLINE_STORAGE_GUIDE.md:5-7`, `:11-18`, `:20-24`).
- The architecture guide expects Flutter presentation, state, data, and domain layers (`SYSTEM_ARCHITECTURE.md:36-41`).
- The state guide recommends Riverpod or BLoC, immutable states, repositories, loading/success/error states, and cached responses (`STATE_MANAGEMENT_GUIDE.md:3-24`).

Backend implementation evidence:

- Actual backend routes are mounted for `/auth`, `/lessons`, `/vocabulary`, `/bookmarks`, `/progress`, `/quiz`, and `/dashboard` (`MaiHongo_BE/src/server.ts:35-41`).
- Protected lesson, vocabulary, bookmark, progress, quiz, and dashboard routes require `authMiddleware` (`MaiHongo_BE/src/routes/*.ts`).
- Auth returns `{ token }` only, with no refresh token or profile payload (`authService.ts:22-23`, `:36-37`).
- `responseSuccess` wraps successful responses in `{ success, message, data, pagination }` (`response.ts:28-38`).
- Lesson list returns only `title category description`, while detail populates `vocabIds` (`lessonRepository.ts:3-5`).
- Lesson model includes `isOfflineReady` (`Lesson.ts:5-10`).
- Vocabulary has no audio URL, speech metadata, writing prompt, or media fields (`Vocabulary.ts:11-20`).
- Quiz type is limited to `multiple_choice` and `typing` (`QuizResult.ts:7`, `quizValidation.ts:6`).

Flutter evidence:

- Flutter `pubspec.yaml` includes UI helpers plus `shared_preferences` and `isar`, but no HTTP client, Riverpod/BLoC, connectivity, audio playback, recording, speech, secure storage, or file cache package (`pubspec.yaml:10-24`).
- Flutter `lib` folders are only `screens`, `theme`, `data`, and `widgets`; there are no model/service/repository/state folders.
- Navigation is centralized in `main.dart` using callbacks and named routes (`main.dart:25-60`, `:84-124`).
- Static vocabulary, categories, and quiz questions live in `vocab_data.dart` (`vocab_data.dart:7-16`, `:26-33`, `:42-46`).
- Auth screens call callbacks only, not APIs (`auth_screens.dart:47`, `:105`).
- Vocabulary bookmark state is an in-memory `Set<int>` (`vocab_screen.dart:15-17`, `:127-130`).
- Saved words use `kVocab.take(5)`, not backend bookmarks (`saved_screen.dart:12`).
- Flashcards use a static internal `_cards` list (`flashcard_screen.dart:12-17`).
- Quiz uses static `kQuestions` and returns only a local score (`quiz_screen.dart:35-49`).
- Settings have an "Offline Downloads" row but no navigation or implementation (`settings_screen.dart:68-74`).
- There is no `test/` directory.

React admin evidence:

- React admin is also prototype-like: auth is local state only (`MaiHonGo_FE/src/app/App.tsx:33-49`).
- It contains conceptual admin pages for lesson, vocabulary, quiz, bookmarks, offline sync, notifications, analytics, and users (`App.tsx:64-74`).
- Offline sync page references packages, audio assets, image cards, and lesson data, but these are static arrays (`OfflineSync.tsx:7-13`, `:65-69`).
- Vocabulary admin UI mentions audio bulk upload and optional audio, but backend does not yet model or expose audio assets (`VocabularyManagement.tsx:41-43`, `:154-157`).

## 4. Gap Analysis

### Completed and Correct

- Backend core layering is present: controllers, services, repositories, validations, DTOs, middleware, and centralized response/error utilities.
- Backend core learner APIs exist for the original scope: auth, lessons, vocabulary, bookmarks, progress, quiz results, dashboard.
- Backend models align with the original documented MongoDB collections for users, lessons, vocabulary, bookmarks, progress, and quiz results.
- Flutter static UI prototype is visually complete for the original learning flow.
- Flutter analyzer passes.
- Backend TypeScript compile check passes.

### Implemented but Inconsistent with Backend

- Flutter auth screens do not call `/auth/register` or `/auth/login`, store JWTs, or handle backend response envelopes.
- Flutter lesson/category screens use static categories instead of `GET /lessons`.
- Flutter vocabulary screen uses static `kVocab`, not `GET /vocabulary?tag=&q=`.
- Flutter bookmarks use local index state and `kVocab.take(5)`, not `GET/POST/DELETE /bookmarks`.
- Flutter quiz flow does not save quiz results to `POST /quiz/results`.
- Flutter progress is visual only and does not use `PUT /progress`, `GET /progress`, or `GET /dashboard/summary`.

### Implemented but Inconsistent with Documentation

- The documentation expects local storage/offline usage, but Flutter does not use Isar or SharedPreferences anywhere in `lib`.
- The documentation expects state management and repositories, but Flutter uses screen-local `setState` and callbacks only.
- The SRS says logout clears tokens locally, but there are no real tokens to clear.
- The SRS says offline learning supports downloaded lessons; Flutter only has a settings row for offline downloads.
- The SRS says quiz history is saved; Flutter only shows a local result screen.

### Partially Implemented

- Authentication: screens exist, no backend integration.
- Dashboard/home: screen exists, no dashboard API.
- Lessons/categories: UI exists, no real lesson list/detail integration.
- Vocabulary: UI and local filtering exist, no API search or persisted favorites.
- Flashcards: flip/swipe UI exists, no backend content/progress/bookmark integration.
- Quiz: multiple-choice UI exists, no typing quiz, no backend save, no history.
- Bookmarks: saved words UI exists, no backend bookmark list.
- Profile/settings: UI exists, no user API or local preference persistence.
- Offline: dependencies mention Isar and settings row exists, no implementation.

### Missing

- Flutter API client and response envelope handling.
- Flutter auth token lifecycle and route guard.
- Flutter model/DTO mapping for backend `_id`, `vocabIds`, `meaningVi`, `examples`, timestamps.
- Repository layer.
- State management layer.
- Local database schema and adapters.
- Connectivity detection.
- Sync queue.
- Downloaded lesson/package management.
- Loading, empty, error, and offline states.
- Listening practice.
- Speaking practice.
- Writing practice.
- Audio playback and audio cache.
- Voice recording, microphone permissions, upload/evaluation abstraction.
- Writing submission/history/feedback.
- Automated Flutter tests.

### Technical Debt and Architecture Issues

- Hardcoded data creates a high risk of false progress in demos.
- `isar` and `shared_preferences` are declared but unused.
- `flip_card` dependency is declared but the app uses a custom flip implementation.
- No API base URL configuration.
- No secure token storage. The docs mention SharedPreferences for token/flags, but security requirements would be better served by `flutter_secure_storage` for tokens and SharedPreferences only for non-sensitive flags.
- No route guard or session restore.
- No consistent error/loading/empty/offline UI.
- No separation between presentation and business/data logic.
- No test seam for backend integration or offline sync.
- Backend docs and OpenAPI disagree with older markdown API examples on response shape.
- Backend lacks refresh token support despite the SRS mentioning JWT expiration and refresh.

## 5. Requirement Extension Analysis

### 5.1 Local Data Management

Business goal: allow learners to access learning content quickly, preserve progress/bookmarks/preferences, and support intermittent connectivity.

Technical impact:

- Add local database schema.
- Add repository methods that read local data first and refresh from API when online.
- Add migration/versioning strategy.
- Add local cache invalidation and cleanup.

Backend dependencies:

- Existing: lessons, vocabulary, bookmarks, progress, quiz results.
- Needed: content versioning fields, package manifest endpoint, bulk lesson/vocabulary download endpoint, optional `updatedAt` filters.

Frontend dependencies:

- Isar schema models or Drift tables.
- Repository abstractions.
- Sync queue.
- Secure token storage.
- Connectivity detection.

Data model changes:

- Local `LocalLesson`, `LocalVocabulary`, `LocalProgress`, `LocalBookmark`, `LocalQuizResult`, `LocalSyncOperation`, `LocalContentPackage`.
- Add server fields where missing: `version`, `contentHash`, `audioUrl`, `assetSize`, `downloadable`, `updatedAt` in list responses.

Local storage requirements:

- Lessons/vocabulary persisted.
- Auth/session flags stored separately.
- Media assets stored in file cache.
- Pending writes queued.

Sync requirements:

- Pull server content and progress after login.
- Push pending progress/bookmark/quiz operations when online.
- Retry with backoff.
- Last-write-wins for progress per SRS.

Risks:

- ObjectId/string mapping bugs.
- Data migrations under time pressure.
- Large audio assets may exceed storage expectations.
- Queue duplication without idempotency keys.

Complexity: High.

### 5.2 Offline Learning Mode

Business goal: learners can finish downloaded lessons without internet and sync later.

Technical impact:

- Add download/manage offline content UI.
- Add local-first lesson and flashcard flows for downloaded lessons.
- Add offline indicators and blocked-state messaging for content not downloaded.

Backend dependencies:

- Existing `isOfflineReady` field.
- Needed package manifest, versioned bundle download, optional delete/unpublish handling.

Frontend dependencies:

- Isar local content.
- File cache for media.
- Connectivity state.
- Sync queue.
- Offline-aware repositories.

Data model changes:

- `LocalContentPackage` with status, size, downloadedAt, version, manifest.
- `LocalLesson.downloaded`, `LocalLesson.version`, `LocalLesson.lastSyncedAt`.

Local storage requirements:

- Required lesson detail and vocabulary documents.
- Practice progress and queue.
- Optional audio/media.

Sync requirements:

- Download flow: fetch manifest, validate space, fetch content/media, store transactionally.
- Offline usage: read local content and write local attempts/progress.
- Sync flow: push pending changes, pull latest progress/content versions, clear queue.

Risks:

- Partial downloads.
- Stale content.
- User confusion about unavailable online-only content.
- Conflict handling for progress.

Complexity: High.

### 5.3 Listening Practice

Business goal: improve recognition and pronunciation comprehension through audio-based practice.

Technical impact:

- Add audio playback service.
- Add listening screens, progress state, answer checking, and media cache.
- Add audio asset metadata to backend/content.

Backend dependencies:

- Missing: audio URL/storage for vocabulary or listening items.
- Missing: listening exercise model and result endpoint.
- Possible fallback: use vocabulary `audioUrl` and save progress through generic progress/quiz endpoints if teacher accepts.

Frontend dependencies:

- Audio player package.
- Audio cache/file storage.
- Listening UI.
- Local attempt storage and sync queue.

Data model changes:

- `ListeningExercise`: lessonId, promptAudioUrl, transcript, choices, answer, speed options.
- `ListeningAttempt`: exerciseId, answer, correct, durationSec, createdAt, syncedAt.
- Add `audioUrl` to vocabulary or lesson assets.

Local storage requirements:

- Audio files.
- Exercise metadata.
- Attempts and progress.

Sync requirements:

- Download exercises and audio with lessons.
- Queue attempts offline.
- Push results when online.

Risks:

- Media hosting/storage not ready.
- Playback compatibility.
- Large downloads.
- Licensing/content source risk.

Complexity: Medium-high.

### 5.4 Speaking Practice

Business goal: help learners practice spoken Japanese and receive feedback/history.

Technical impact:

- Add microphone permission handling.
- Add voice recorder service.
- Add upload/evaluation abstraction.
- Add local attempt history.

Backend dependencies:

- Missing: speaking prompt model.
- Missing: recording upload endpoint.
- Missing: evaluation endpoint/result schema.
- If backend cannot evaluate speech, define a service interface and store attempts locally until backend is ready.

Frontend dependencies:

- Recorder package.
- Permission package.
- Local file storage.
- Optional speech-to-text or backend evaluation client.

Data model changes:

- `SpeakingPrompt`: prompt text/audio, expected reading, lessonId.
- `SpeakingAttempt`: local file path, remote file URL, score, transcript, feedback, sync state.

Local storage requirements:

- Temporary recording files.
- Attempt metadata and sync queue.

Sync requirements:

- Queue recording upload.
- Upload when online.
- Poll/evaluate or receive immediate result.
- Clean old local files after successful upload if policy allows.

Risks:

- Backend speech evaluation may be unavailable.
- Mobile permission edge cases.
- Storage growth from recordings.
- Privacy concerns for voice data.

Complexity: High.

### 5.5 Writing Practice

Business goal: develop productive recall through typing, sentence writing, and correction feedback.

Technical impact:

- Add writing prompts, text input, local drafts, submissions, feedback display, and history.
- Potentially support handwriting later, but start with text input unless teacher explicitly requires handwriting.

Backend dependencies:

- Missing: writing prompt endpoint.
- Missing: writing submission endpoint.
- Missing: correction/feedback endpoint.
- Optional: dictionary/grammar feedback integration.

Frontend dependencies:

- Writing screens.
- Draft persistence.
- Local submission queue.
- Feedback/revision UI.

Data model changes:

- `WritingPrompt`: lessonId, promptVi/en, expectedPattern, vocabularyIds, rubric.
- `WritingSubmission`: text, score, corrections, feedback, createdAt, syncedAt.

Local storage requirements:

- Prompts.
- Drafts.
- Submissions and feedback.

Sync requirements:

- Queue submissions offline.
- Push when online.
- Pull feedback when processed.

Risks:

- Feedback quality depends on backend.
- Rubric ambiguity.
- If handwriting is required, scope increases significantly.

Complexity: Medium-high for typing, high for handwriting.

## 6. Flutter Architecture Review

Current state management:

- Screen-local `setState`.
- Callback-based navigation.
- No Provider/Riverpod/BLoC/ChangeNotifier.

Assessment: acceptable for a visual prototype; not acceptable for backend-integrated offline learning.

Repository pattern:

- Missing.

API layer:

- Missing. No HTTP client dependency, no base URL, no auth interceptor, no response envelope parser.

Local storage:

- Dependencies exist for `shared_preferences` and `isar`, but no usage exists in `lib`.

Offline readiness:

- Not implemented. No local cache, no queue, no download manager, no connectivity detection.

Scalability issues:

- Hardcoded static data is spread into screens and `data/vocab_data.dart`.
- Feature screens own too much behavior.
- No typed server/local model boundary.
- No generated local database models.
- No testable service contracts.

Testing coverage:

- No Flutter test directory.
- Analyzer passes, but there are no unit/widget/integration tests.

Recommended architecture, minimal rewrite:

```text
lib/
  core/
    config/
    network/
    storage/
    sync/
    errors/
  features/
    auth/
      models/
      data/
      state/
      screens/
    lessons/
    vocabulary/
    flashcards/
    quiz/
    bookmarks/
    progress/
    offline/
    listening/
    speaking/
    writing/
  shared/
    widgets/
    theme/
```

Recommended state management: Riverpod, because it matches the documentation example, is test-friendly, and can support repository injection cleanly. BLoC is also acceptable if the team already knows it better. Avoid mixing multiple major state patterns.

Recommended data access:

- `ApiClient` handles base URL, JSON, auth header, response envelope, and API errors.
- Feature repositories coordinate API plus local store.
- Local store uses Isar, since it is already in `pubspec.yaml` and fits object-style lesson/vocabulary data.
- Use SharedPreferences only for simple settings/onboarding flags; use secure storage for tokens if allowed.

## 7. Existing Feature Audit

| Feature | Current Status | Flutter Screens | Backend APIs Used/Available | Models Used | Issues Found | Required Fixes | Effort |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Splash/onboarding | Partial | `splash_screen.dart`, `onboarding_screen.dart` | None needed | Local UI only | Onboarding completion not persisted | Store onboarding flag; session restore | S |
| Authentication | Needs refactor | `auth_screens.dart` | Available: `POST /auth/register`, `POST /auth/login` | None | No API call, no validation submission, no token storage, social buttons are decorative | Add auth repository, token storage, form validation, loading/error states, route guard | M |
| Home/dashboard | Partial | `home_screen.dart` | Available: `GET /dashboard/summary`, `GET /progress` | None | Hardcoded user, streak, XP, progress, continue lesson | Connect dashboard/progress APIs and local fallback | M |
| Lessons/categories | Partial | `categories_screen.dart`, `vocab_screen.dart` | Available: `GET /lessons`, `GET /lessons/:id` | `CategoryItem`, `VocabItem` static | Category concept does not map cleanly to backend lessons; no lesson detail fetch | Add lesson models/repository; map category/tag; support downloaded state | M |
| Vocabulary/search | Partial | `vocab_screen.dart` | Available: `GET /vocabulary?tag=&q=` | `VocabItem` static | Search field does not search; filter local only; field names differ from backend | Add vocabulary model with `_id`, `hiragana`, `meaningVi`, `examples`, `tags`; implement search/filter | M |
| Flashcards | Partial | `flashcard_screen.dart`, `widgets/flashcard.dart` | Available through lesson detail and progress APIs | Static maps | Static cards; swipe known/unknown not saved; audio icon inactive | Load lesson vocabulary; save progress; bookmark; audio playback if available | M |
| Quiz | Partial | `quiz_screen.dart`, `result_screen.dart` | Available: `POST /quiz/results`, `GET /quiz/results` | `QuizQuestion` static | Multiple-choice only; no typing quiz; result not saved; no quiz history | Add quiz repository; support typing; save result; local queue offline | M |
| Bookmarks/favorites | Partial | `vocab_screen.dart`, `saved_screen.dart` | Available: `GET/POST/DELETE /bookmarks` | Static indexes | In-memory `_saved`; saved screen takes first 5 words | Implement bookmark repository; optimistic local update; sync queue | M |
| Progress tracking | Missing | Visual progress in multiple screens | Available: `PUT /progress`, `GET /progress`, `GET /progress/:lessonId` | None | Only hardcoded percentages | Persist lesson progress, last viewed index, quiz score; sync offline changes | M |
| Profile | Partial | `profile_screen.dart` | Missing profile endpoint | None | Hardcoded user, badges, streaks, stats | Backend profile/achievements dependency or derive from progress; local settings | M |
| Settings | Partial | `settings_screen.dart` | None | None | Toggles not persisted; offline downloads row not functional; logout only navigates | Persist settings, clear token on logout, add offline downloads screen | S-M |
| Notifications | Missing in Flutter | None | Missing push notification backend | None | React admin has conceptual notification page only | Define push strategy later; not critical for teacher extension unless required | M |
| Local data | Missing | None | Existing content APIs only | None | Isar dependency unused | Add Isar schemas, migrations, repository cache | H |
| Offline learning | Missing | Settings row only | Existing APIs insufficient for full package/version flow | None | No download flow, queue, or offline indicators | Add download manager, local-first lesson flow, sync queue | H |
| Listening practice | Missing | None | Missing backend model/API | None | No audio asset model or player package | Define backend contract; add player/cache UI | M-H |
| Speaking practice | Missing | None | Missing backend model/API | None | No recorder/evaluation/permissions | Define service abstraction; add recorder and attempt history | H |
| Writing practice | Missing | None | Missing backend model/API | None | No prompt/submission/feedback model | Add typing writing module first; backend contracts for submissions | M-H |

Status key: S = small, M = medium, H = high.

## 8. Local Data and Offline Strategy

### Technology Evaluation

| Technology | Strength | Weakness | Recommendation |
| --- | --- | --- | --- |
| Hive | Simple key-value/object storage, fast setup | Less strong for relational queries and migrations | Acceptable fallback, not primary |
| Isar | Already declared, fast local object DB, good for object graphs | Requires generated schemas and migration discipline | Recommended primary local DB |
| Drift/SQLite | Excellent relational modeling and SQL queries | More boilerplate, larger setup cost | Consider only if complex relational/reporting needs dominate |
| SharedPreferences | Simple flags/settings | Not suitable for large content or sensitive tokens | Use only for non-sensitive flags/settings |

Recommended storage stack:

- Isar: lessons, vocabulary, bookmarks, progress, quiz results, practice attempts, sync queue, package manifests.
- SharedPreferences: onboarding complete, selected language, simple UI preferences.
- Secure storage, if allowed: auth token. If the teacher requires SharedPreferences strictly, document security tradeoff.
- File cache: audio files, recordings, downloaded media.

### Data to Cache

- Lesson list.
- Lesson detail with vocabulary.
- Vocabulary list/search results by tag.
- Dashboard summary, as stale-while-revalidate.
- Quiz history.
- Bookmark list.

### Data to Persist

- Downloaded lesson content.
- Downloaded audio/listening assets.
- Local progress and last viewed index.
- Bookmark add/delete operations.
- Quiz results.
- Listening attempts.
- Speaking attempts and recording metadata.
- Writing drafts/submissions/feedback.
- Sync queue.

### Offline Approach

Use an online-first bootstrap with local-first behavior for downloaded lessons:

- If online, fetch and refresh.
- If offline and downloaded, read from local.
- If offline and not downloaded, show an unavailable state and prompt download when online.
- All learner-generated changes write locally first and enqueue sync operations.

### Conflict Resolution

- Progress: last-write-wins using `updatedAt`, matching the SRS.
- Bookmarks: use idempotent add/delete operations; delete wins if timestamps conflict.
- Quiz/listening/speaking/writing attempts: append-only. Do not merge attempts.
- Content: server wins. Local content is read-only cache by version.

### Download Flow

1. User opens Offline Downloads.
2. App fetches package/lesson manifest.
3. App checks available storage and network state.
4. App downloads lesson JSON and media assets.
5. App writes content transactionally to Isar.
6. App marks package as downloaded with version, size, and timestamp.
7. UI shows downloaded/offline-ready badge.

### Offline Usage Flow

1. App detects offline state.
2. User opens downloaded lesson.
3. Repository serves content from Isar.
4. Progress/bookmarks/attempts write to local DB.
5. Sync queue records pending operations.
6. UI displays offline indicator and pending sync count.

### Sync Flow

1. Connectivity changes to online or app starts online.
2. Sync manager authenticates with stored token.
3. Sync manager pushes queue in deterministic order: progress, bookmarks, quiz, listening, speaking, writing.
4. Sync manager retries transient failures with backoff.
5. Sync manager pulls server progress/bookmarks/content versions.
6. Queue items are marked synced or failed with reason.

### Error Handling

- Network timeout: keep local changes queued.
- Unauthorized: pause sync and require login.
- Validation error: mark queue item failed and show recoverable message.
- Partial download: resume or clear incomplete package.
- Storage full: block download with clear size message.

## 9. Dependency Mapping

| Feature | Required APIs | Required Local Storage | Required UI | Required Business Logic | Required Sync | Required Testing |
| --- | --- | --- | --- | --- | --- | --- |
| Auth | `/auth/register`, `/auth/login` | token/session flags | Login/register/loading/errors | validation, auth state, route guard | none except token refresh if added | unit auth repo, widget forms |
| Dashboard | `/dashboard/summary`, `/progress` | cached summary/progress | home cards | aggregate and stale data handling | pull refresh | widget + repository tests |
| Lessons | `/lessons`, `/lessons/:id` | lesson/vocab cache | categories, lesson detail | content mapping | pull/download | model mapping, offline read |
| Vocabulary | `/vocabulary` | vocab cache/search index | list/search/filter | search debounce, tag filter | pull/download | repository and UI states |
| Flashcards | lesson detail, `/progress`, bookmarks | session progress | card/review UI | known/unknown, last index | progress queue | widget and progress tests |
| Quiz | `/quiz/results` | questions/results/queue | quiz/result/history | scoring, typing validation | result queue | scoring unit tests |
| Bookmarks | `/bookmarks` | local bookmark table/queue | save/review UI | optimistic add/delete | bookmark queue | repository conflict tests |
| Offline downloads | new manifest/bundle endpoints | packages, content, files | download manager | versioning, storage checks | pull/sync | download state tests |
| Listening | new listening/audio endpoints | audio/exercises/attempts | audio player/practice | answer checking, speed | attempt queue | audio state/mock tests |
| Speaking | new speaking/upload/eval endpoints | recordings/attempts | recorder/history | permissions, upload, feedback | upload/eval queue | permission/service tests |
| Writing | new writing/submission endpoints | prompts/drafts/submissions | writing editor/history | draft, submit, correction | submission queue | draft/sync tests |

Blocking tasks:

- API client and response envelope parser.
- Auth/token storage.
- Local database schema.
- Repository/state pattern decision.
- Backend contracts for listening, speaking, writing.

Parallelizable tasks after blockers:

- Auth integration and route guard.
- Lesson/vocabulary repository and UI mapping.
- Bookmark/progress sync.
- Offline downloads UI and local package manager.
- Listening UI with mock backend contract.
- Speaking UI with service abstraction.
- Writing UI with local draft support.
- Test harness and mock repositories.

Shared modules:

- `core/network`
- `core/storage`
- `core/sync`
- `core/errors`
- `features/auth`
- `shared/widgets`

High-risk modules:

- Sync queue.
- Offline package downloads.
- Speaking upload/evaluation.
- Backend response/model mismatch handling.

## 10. Team Planning for 5 Members

### Member 1: Flutter Architecture and API Integration Lead

Responsibilities:

- Own Flutter app architecture, API client, auth flow, DTO/model mapping, repository conventions, and state management setup.

Existing features assigned:

- Authentication, navigation/session restore, API response handling, base app state.

Existing features to review/fix:

- `auth_screens.dart`, `main.dart`, route guard, form validation, logout behavior.

Extended features assigned:

- Shared architecture required by all extended features.

Backend dependencies:

- `/auth/register`, `/auth/login`; response envelope; JWT expiration behavior.

Frontend dependencies:

- State management package, HTTP client, token storage, config.

Files/folders expected to change:

- `lib/main.dart`
- `lib/core/network/**`
- `lib/core/config/**`
- `lib/core/storage/**`
- `lib/features/auth/**`

Testing responsibility:

- Auth repository tests, API client envelope/error tests, login/register widget tests.

Complexity: High.

Deliverables:

- Stable app shell, auth integration, API client, repository/state template, route guard.

### Member 2: Learning Content and Offline Lead

Responsibilities:

- Own lessons, vocabulary, flashcards, local database, downloads, and offline content access.

Existing features assigned:

- Lessons/categories, vocabulary, flashcards.

Existing features to review/fix:

- `categories_screen.dart`, `vocab_screen.dart`, `flashcard_screen.dart`, `widgets/flashcard.dart`, `data/vocab_data.dart`.

Extended features assigned:

- Local data and offline learning.

Backend dependencies:

- `/lessons`, `/lessons/:id`, `/vocabulary`; needed manifest/bulk-download/version endpoints.

Frontend dependencies:

- Isar schemas, file cache, connectivity, sync manager hooks.

Files/folders expected to change:

- `lib/features/lessons/**`
- `lib/features/vocabulary/**`
- `lib/features/flashcards/**`
- `lib/features/offline/**`
- `lib/core/storage/**`

Testing responsibility:

- Local DB tests, lesson/vocabulary model mapping, offline read tests, download state tests.

Complexity: High.

Deliverables:

- Real lesson/vocabulary data flow, local content cache, offline downloads MVP.

### Member 3: Listening and Speaking Practice Lead

Responsibilities:

- Own audio playback, listening practice, voice recording, permissions, and speaking attempt history.

Existing features assigned:

- Audio icons in vocabulary/flashcards and sound settings.

Existing features to review/fix:

- Inactive audio buttons in `vocab_screen.dart` and `widgets/flashcard.dart`; settings audio toggle.

Extended features assigned:

- Listening practice and speaking practice.

Backend dependencies:

- Needed audio asset fields/endpoints, listening exercise endpoint, speaking prompt/upload/evaluation endpoints.

Frontend dependencies:

- Audio player, recorder, permission handling, file cache, local attempts.

Files/folders expected to change:

- `lib/features/listening/**`
- `lib/features/speaking/**`
- `lib/core/media/**`
- `lib/core/storage/**`

Testing responsibility:

- Mock player/recorder tests, permission state tests, attempt queue tests.

Complexity: High.

Deliverables:

- Listening MVP with cached audio; speaking MVP with recording and local/sync-ready attempts.

### Member 4: Quiz, Writing, Progress Lead

Responsibilities:

- Own quiz alignment, typing quiz, writing practice, progress persistence, result/history synchronization.

Existing features assigned:

- Quiz, result screen, progress tracking.

Existing features to review/fix:

- `quiz_screen.dart`, `result_screen.dart`, hardcoded score/history/progress.

Extended features assigned:

- Writing practice and progress sync for all practice modes.

Backend dependencies:

- `/progress`, `/progress/:lessonId`, `/quiz/results`; needed writing prompt/submission/feedback endpoints.

Frontend dependencies:

- Progress repository, quiz repository, local attempts, sync queue.

Files/folders expected to change:

- `lib/features/quiz/**`
- `lib/features/progress/**`
- `lib/features/writing/**`
- `lib/core/sync/**`

Testing responsibility:

- Scoring tests, progress sync tests, writing draft/submission tests.

Complexity: Medium-high.

Deliverables:

- Backend-aligned quiz/results, progress persistence, writing MVP with local drafts/submissions.

### Member 5: Product, QA, UI Consistency, and Scrum Lead

Responsibilities:

- Own feature acceptance criteria, existing UI consistency, QA plan, manual test scripts, sprint tracking, and low-risk UI alignment.

Existing features assigned:

- Saved/bookmarks UI, profile, settings, onboarding, QA review across all screens.

Existing features to review/fix:

- `saved_screen.dart`, `profile_screen.dart`, `settings_screen.dart`, `onboarding_screen.dart`, shared widgets.

Extended features assigned:

- Offline indicators, empty/error states, QA support for local/offline/listening/speaking/writing.

Backend dependencies:

- Bookmarks APIs; profile endpoint if added; notification/profile requirements if teacher expands scope.

Frontend dependencies:

- Shared UI components for loading/error/empty/offline, mock repository fixtures.

Files/folders expected to change:

- `lib/shared/widgets/**`
- `lib/features/bookmarks/**`
- `lib/features/profile/**`
- `lib/features/settings/**`
- QA docs/checklists.

Testing responsibility:

- Widget tests for shared states, manual regression checklist, sprint acceptance verification.

Complexity: Medium.

Deliverables:

- Consistent UI states, QA checklist, acceptance test coverage, sprint board hygiene.

## 11. Detailed Task Breakdown

### Member 1 Tasks

| Task ID | Description | Priority | Dependencies | Effort | Definition of Done |
| --- | --- | --- | --- | --- | --- |
| M1-A1 | Choose and add state management and HTTP approach | P0 | Team agreement | 0.5d | Architecture decision recorded; dependencies added |
| M1-A2 | Implement `ApiClient` with response envelope parsing | P0 | M1-A1 | 1d | Handles success/error, bearer token, base URL config |
| M1-A3 | Create auth models/repository | P0 | M1-A2 | 1d | Login/register parse backend response correctly |
| M1-A4 | Integrate auth screens with loading/error states | P0 | M1-A3 | 1d | Real auth flow reaches main shell |
| M1-A5 | Add token/session restore and logout clear | P0 | M1-A3 | 1d | App opens correct route based on session |
| M1-A6 | Add API/repository test harness | P1 | M1-A2 | 1d | Mock API tests pass locally |

### Member 2 Tasks

| Task ID | Description | Priority | Dependencies | Effort | Definition of Done |
| --- | --- | --- | --- | --- | --- |
| M2-A1 | Define Isar schemas for lessons/vocabulary/packages | P0 | M1-A1 | 1.5d | Generated schemas compile |
| M2-A2 | Implement lesson/vocabulary repositories | P0 | M1-A2, M2-A1 | 2d | `GET /lessons`, detail, and vocabulary search map to UI |
| M2-A3 | Replace static category/vocab content | P1 | M2-A2 | 1.5d | Screens load real/cached content |
| M2-A4 | Connect flashcards to lesson vocabulary | P1 | M2-A2 | 1d | Flashcard session starts from selected lesson |
| M2-B1 | Build offline download manager MVP | P1 | M2-A1 | 2d | Lesson can be marked downloaded and read offline |
| M2-B2 | Add offline download screen from settings | P1 | M2-B1 | 1d | User sees downloaded/available lessons |

### Member 3 Tasks

| Task ID | Description | Priority | Dependencies | Effort | Definition of Done |
| --- | --- | --- | --- | --- | --- |
| M3-A1 | Define audio asset contract with backend | P0 | Product/backend agreement | 0.5d | Fields/endpoints documented |
| M3-A2 | Add media playback service abstraction | P1 | M3-A1 | 1d | Mockable service controls play/pause/replay |
| M3-A3 | Implement listening practice screen MVP | P1 | M3-A2, M2-A1 | 2d | Audio question can be answered and stored locally |
| M3-A4 | Add audio caching for downloaded lessons | P2 | M2-B1, M3-A2 | 1.5d | Downloaded audio plays offline |
| M3-B1 | Add recorder and permission service abstraction | P1 | Package selection | 1d | Permission states handled |
| M3-B2 | Implement speaking practice MVP | P2 | M3-B1 | 2d | User records, reviews, saves attempt locally |
| M3-B3 | Integrate speaking upload/evaluation if backend ready | P2 | Backend endpoint | 2d | Attempt syncs and displays feedback |

### Member 4 Tasks

| Task ID | Description | Priority | Dependencies | Effort | Definition of Done |
| --- | --- | --- | --- | --- | --- |
| M4-A1 | Implement progress repository | P0 | M1-A2, M2-A1 | 1.5d | `PUT/GET /progress` works and queues offline |
| M4-A2 | Save flashcard progress | P1 | M4-A1, M2-A4 | 1d | Last viewed index and completion persist |
| M4-A3 | Align quiz with backend result schema | P1 | M1-A2 | 1d | Quiz result posts or queues with `durationSec` |
| M4-A4 | Add typing quiz support | P1 | M4-A3 | 1.5d | Multiple-choice and typing modes supported |
| M4-B1 | Define writing backend contract | P1 | Product/backend agreement | 0.5d | Prompt/submission/feedback schema documented |
| M4-B2 | Implement writing practice MVP | P2 | M4-B1, M2-A1 | 2d | User drafts/submits writing locally |
| M4-B3 | Sync writing submissions/feedback | P2 | Backend endpoint | 2d | Submissions sync and feedback displays |

### Member 5 Tasks

| Task ID | Description | Priority | Dependencies | Effort | Definition of Done |
| --- | --- | --- | --- | --- | --- |
| M5-A1 | Create acceptance criteria checklist per feature | P0 | This report | 0.5d | Checklist available for sprint reviews |
| M5-A2 | Implement shared loading/error/empty/offline widgets | P0 | M1-A1 | 1d | Widgets reused by feature screens |
| M5-A3 | Connect bookmarks UI to repository | P1 | M1-A2, M2-A1 | 1.5d | Saved screen uses real/cached bookmarks |
| M5-A4 | Persist settings/onboarding flags | P1 | Storage decision | 1d | Toggles and onboarding persist |
| M5-A5 | Define manual QA scripts | P1 | Feature contracts | 1d | Scripts cover online/offline/auth/practice |
| M5-A6 | Add widget tests for shared states | P1 | M5-A2 | 1d | Tests cover loading/error/empty/offline |
| M5-B1 | Run sprint regression and bug triage | P1 | Sprint builds | ongoing | Bugs logged, prioritized, assigned |

## 12. Sprint Plan

### Sprint 1: Architecture, API Alignment, and Existing Feature Audit Fixes

Goals:

- Turn static prototype into an integrated app foundation.
- Resolve backend response shape and auth/session handling.
- Establish local DB/schema baseline and test harness.

Tasks:

- M1-A1 to M1-A6
- M2-A1, M2-A2
- M4-A1
- M5-A1, M5-A2
- Backend contract review for local/offline and practice extensions

Assigned members:

- Member 1 leads architecture/auth.
- Member 2 starts local content schema.
- Member 4 starts progress.
- Member 5 owns QA criteria/shared states.
- Member 3 defines audio/speaking contracts and package choices.

Dependencies:

- Backend base URL and environment.
- Final state-management decision.
- Agreement on token storage.

Risks:

- API docs mismatch causes model rework.
- Isar generator/setup may slow first sprint.
- Lack of test fixtures.

Definition of Done:

- Login/register work against backend.
- API envelope parsed consistently.
- Analyzer passes.
- First unit/widget tests exist.
- Lessons/vocabulary repositories compile with real DTOs.

### Sprint 2: Existing Feature Integration and Offline MVP

Goals:

- Replace hardcoded learning data with backend/local repositories.
- Implement bookmarks, flashcards, quiz result saving, and progress.
- Deliver offline lesson download/read MVP.

Tasks:

- M2-A3, M2-A4, M2-B1, M2-B2
- M4-A2, M4-A3, M4-A4
- M5-A3, M5-A4, M5-A5
- Member 3 starts M3-A2, M3-A3 if audio contract is ready

Assigned members:

- Member 2 owns lessons/vocabulary/offline.
- Member 4 owns quiz/progress.
- Member 5 owns bookmarks/settings/QA.
- Member 1 supports API/state issues.
- Member 3 begins listening groundwork.

Dependencies:

- Sprint 1 architecture complete.
- Backend content data available.
- Offline manifest workaround or temporary per-lesson download strategy approved.

Risks:

- Backend lacks package/version endpoints.
- Content list and detail models may not include enough fields.
- Offline queue bugs can affect progress/bookmarks.

Definition of Done:

- Static data is removed or isolated behind mock fixtures only.
- Lessons/vocabulary/flashcards use real or cached data.
- Progress, bookmarks, and quiz results persist locally and sync online.
- Offline downloaded lesson can be reviewed without internet.

### Sprint 3: Teacher Extensions, Stabilization, and QA

Goals:

- Implement listening, speaking, and writing MVPs.
- Stabilize offline sync and practice histories.
- Complete regression testing and final documentation.

Tasks:

- M3-A3, M3-A4, M3-B1, M3-B2, M3-B3 if backend ready
- M4-B1, M4-B2, M4-B3 if backend ready
- M5-A6, M5-B1
- Cross-team bug fixing and QA stabilization

Assigned members:

- Member 3 owns listening/speaking.
- Member 4 owns writing/progress histories.
- Member 2 supports local storage/media cache.
- Member 1 supports API integration.
- Member 5 leads QA and sprint closure.

Dependencies:

- Backend contracts for listening/speaking/writing.
- Media hosting/upload decision.
- Evaluation/feedback decision for speaking/writing.

Risks:

- Backend evaluation endpoints may not be ready.
- Audio/recording device behavior varies.
- Writing feedback scope may expand.

Definition of Done:

- Listening MVP works with cached audio.
- Speaking MVP records and stores attempts, syncs if backend ready.
- Writing MVP stores drafts/submissions, syncs if backend ready.
- Offline sync queue handles all implemented learner-generated changes.
- Analyzer and tests pass.
- Manual QA checklist completed.

## 13. Implementation Guidelines

1. Keep the current visual style where possible. Refactor screen internals to consume state/repositories rather than replacing the UI.
2. Treat backend `responseSuccess` envelope as the source of truth, not the older raw-array markdown examples.
3. Normalize backend `_id` to app model `id`, but preserve original server IDs for sync.
4. Add loading, error, empty, and offline states to every network-backed screen.
5. Introduce local storage before offline features, not after.
6. Write all user-generated changes locally first, then sync.
7. Avoid adding listening/speaking/writing directly into old quiz code. Use separate feature modules with shared attempt/progress abstractions.
8. Define backend contracts for teacher extensions before coding API integration.
9. Use mock repositories only inside tests or explicit development fixtures.
10. Add tests with each shared module and high-risk sync path.

## 14. Files Changed

Analysis-only file added:

- `PROJECT_ANALYSIS_REPORT.md`

No application source files were changed.

## 15. Features Implemented

None in this phase. The teacher request explicitly required discovery and analysis before implementation.

## 16. APIs Integrated

None in Flutter yet. Backend APIs available for future integration:

- `POST /auth/register`
- `POST /auth/login`
- `GET /lessons`
- `GET /lessons/:id`
- `GET /vocabulary`
- `GET /bookmarks`
- `POST /bookmarks`
- `DELETE /bookmarks/:vocabId`
- `GET /progress`
- `PUT /progress`
- `GET /progress/:lessonId`
- `GET /quiz/results`
- `POST /quiz/results`
- `GET /dashboard/summary`

## 17. Remaining Backend Dependencies

Required for stronger offline/local data:

- Package manifest endpoint.
- Bulk lesson/vocabulary download endpoint.
- Content versioning/hash fields.
- Optional `updatedAt` query filters.
- Idempotency support for sync operations.

Required for listening:

- Audio asset storage and URL fields.
- Listening exercise endpoint.
- Listening result/attempt endpoint.

Required for speaking:

- Speaking prompts endpoint.
- Recording upload endpoint.
- Speaking evaluation result endpoint.
- Privacy/storage policy for voice recordings.

Required for writing:

- Writing prompts endpoint.
- Writing submission endpoint.
- Feedback/correction endpoint.

Potentially required for profile/settings:

- Current user profile endpoint.
- Achievement/streak/stat endpoints, or accepted derivation rules from progress/quiz history.

## 18. Known Limitations

- This report is based on static source inspection and local compile/analyze checks, not live API calls against a running backend and database.
- No Flutter integration tests exist yet.
- The teacher's extended requirements are broad; acceptance criteria for listening/speaking/writing must be confirmed before final implementation.
- Backend has no seed data inspection in this pass, so content availability is unknown.
- React admin appears to be a prototype and should not be treated as backend-complete evidence.

## 19. Risks and Recommendations

Top risks:

1. Offline sync is the largest architectural risk and should be designed early.
2. Speaking evaluation depends on backend or third-party capability not currently present.
3. Media/audio support affects storage, downloads, and backend schema.
4. Static Flutter screens may hide integration gaps unless hardcoded data is removed quickly.
5. No tests means regressions are likely once repositories/state management are introduced.

Recommended next steps:

1. Approve Riverpod plus Isar as the Flutter architecture baseline.
2. Add API client/auth/session storage first.
3. Add local schemas and repositories before changing all screens.
4. Integrate original existing features before building teacher extensions.
5. Define backend contracts for listening, speaking, writing, and offline packages.
6. Add minimal tests in Sprint 1 and grow coverage around sync and practice scoring.
