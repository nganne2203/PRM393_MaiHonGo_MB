# MaiHonGo Acceptance Criteria Checklist

Owner: Member 5

Use this checklist during sprint review. Mark each item as pass, fail, or not applicable.

## Auth and Session

- Login and register show loading, validation, error, and success states.
- Access and refresh tokens are saved after auth and cleared on logout.
- App restore opens main shell for a valid session.
- App restore opens login for returning unauthenticated users who completed onboarding.
- App restore opens onboarding only for first-time unauthenticated users.

## Onboarding and Settings

- Skip and Get Started both persist onboarding completion.
- Dark mode, notifications, and sound effects toggles persist after app restart.
- Offline Downloads and Privacy & Security rows navigate to their target screens.
- Logout clears auth state and returns to login.

## Lessons, Vocabulary, and Flashcards

- Lessons show loading, cached/offline, empty, and error states consistently.
- Vocabulary loads by lesson, supports search/tag filtering, and shows cached/offline state.
- Audio controls fail gracefully when audio is unavailable.
- Flashcards load from selected lesson vocabulary and show empty/offline states.
- Flashcard review result records learned and not-learned counts.

## Bookmarks and Saved Words

- Vocabulary and flashcard bookmark controls use the backend bookmark API.
- Saved Words screen reads backend bookmarks when online.
- Saved Words screen falls back to cached bookmarks when the API is unavailable.
- Removing a bookmark updates the UI optimistically and reverts on failure.
- Empty and search-with-no-results states are clear and consistent.

## Offline Downloads and Sync

- Offline Downloads lists available and downloaded lesson packages.
- Downloaded lessons remain visible without network.
- Offline indicators are visible on cached content.
- Pending learner-generated changes are retained locally until sync.
- Sync failures do not discard local progress, attempts, or bookmarks.

## Practice Extensions

- Listening prompts load, submit attempts, and show loading/error/empty states.
- Speaking prompts handle permission, recording, review, submission, and history states.
- Writing prompts support lesson selection, draft/submission flow, feedback, and history states.
- Practice attempts remain usable when backend evaluation is unavailable.

## QA Exit Criteria

- `flutter analyze` has no issues.
- `flutter test` passes.
- Backend build passes if backend dependencies are installed.
- Manual scripts in `docs/qa/manual_qa_scripts.md` are completed for the release candidate.
