# Offline SQLite Storage

MaiHongo Flutter stores downloaded learning content in a local SQLite database managed by `LocalDatabaseService`.

## Database

- File name: `maihongo_local.db`
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

## Lesson Offline Flow

1. `LessonRepository.getLessons()` fetches `/lessons`, saves the result to SQLite, then merges the local `downloaded` state.
2. `LessonRepository.getLesson(id)` fetches `/lessons/:id`, saves the lesson and embedded vocabulary to SQLite, and falls back to SQLite if the API fails.
3. `OfflineRepository.downloadLesson(id)` loads the lesson and vocabulary, saves both locally, and marks the lesson in `content_packages`.
4. Screens show cached content when repositories return `ContentResult.isOffline`.

## Notes

- JSON columns are used for small arrays such as `vocabIds`, `tags`, and examples.
- Server IDs are stored as text primary keys, so remote updates replace cached rows deterministically.
- Future offline queues for progress, quiz, listening, speaking, and writing attempts should be added as new SQLite tables with append-only rows and sync status fields.
