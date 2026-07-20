# Offline SQLite Storage

MaiHongo Flutter stores downloaded learning content in a local SQLite database managed by `LocalDatabaseService`.

## Database

- File name: `maihongo_local.db`
- Schema version: `2`
- Runtime backend:
  - Android, iOS, macOS: `sqflite`
  - Tests and non-mobile desktop: `sqflite_common_ffi`
- Entry point: `lib/core/storage/local_database_service.dart`

## Tables

| Table | Purpose |
| --- | --- |
| `lessons` | Cached lesson list/detail, download flag, version, asset size, and vocabulary IDs. |
| `vocabulary` | Cached vocabulary records, lesson relation, examples JSON, tags JSON, and audio URL. |
| `bookmarks` | Cached user bookmarks with enough vocabulary data to render offline. |
| `content_packages` | Downloaded lesson package status, version, size, and download timestamp. |
| `flashcard_session_results` | Local flashcard session history and sync flag. |
| `practice_content` | Cached listening exercises, speaking prompts, and writing prompts by lesson. |
| `offline_media` | Remote-to-local paths for media downloaded with a lesson package. |
| `sync_operations` | Deduplicated offline operations with retry count and last error. |
| `flashcard_resume` | Current card index and answer state for interrupted sessions. |
| `writing_drafts` | Per-prompt writing drafts saved while the learner types. |

## Lesson Offline Flow

1. `LessonRepository.getLessons()` fetches `/lessons`, saves the result to SQLite, then merges the local `downloaded` state.
2. `LessonRepository.getLesson(id)` fetches `/lessons/:id`, saves the lesson and embedded vocabulary to SQLite, and falls back to SQLite if the API fails.
3. `OfflineRepository.downloadLesson(id)` requests `/offline/packages/:lessonId/download` and stores the lesson, vocabulary, practice content, package metadata, and available audio. It reports per-media progress, accepts cancellation, and falls back to the legacy lesson/vocabulary flow only when the package endpoint is unavailable.
4. Listening, speaking, and writing repositories cache online responses and fall back to package content when the API is unavailable.
5. Removing a package deletes its lesson-owned vocabulary, practice content, package metadata, and downloaded media files.
6. Screens show cached content when repositories return `ContentResult.isOffline`.

## Notes

- JSON columns are used for small arrays such as `vocabIds`, `tags`, and examples.
- Server IDs are stored as text primary keys, so remote updates replace cached rows deterministically.
- Bookmark operations and flashcard results are stored in SQLite. Existing progress, quiz, listening, speaking, and writing queues remain compatible with their repository stores and are coordinated by `SyncManager` on startup, foreground, reconnect, and manual sync.
- SQLite version 2 is created through an explicit migration so existing version 1 installations retain cached learning data.
