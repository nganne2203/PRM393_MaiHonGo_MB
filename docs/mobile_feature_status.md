# Mobile Feature Status

Last updated: 2026-07-20

## Implemented in the completion pass

- Quiz questions and answers are randomized; duplicate choices are removed and one-choice quizzes fall back to typing.
- Saved Words review passes only bookmarked vocabulary to flashcards.
- Flashcards support horizontal swipe, interrupted-session resume, local result history, and retryable progress sync.
- Quiz and listening history screens are available from Settings > Practice History. Pending offline results are included.
- SQLite schema version 2 stores practice content, downloaded media paths, sync operations, flashcard resume state, and writing drafts.
- Offline package downloads consume the backend package bundle, cache vocabulary/listening/speaking/writing/audio content, report media progress, and can be cancelled by the learner.
- Listening, speaking, and writing repositories use downloaded practice content when the backend is unavailable.
- Pending bookmark, progress, quiz, listening, speaking, writing, and flashcard activity is retried on app startup, foreground, connectivity recovery, or Settings > Sync now.
- Listening has 0.75x, 1x, and 1.25x playback controls and updates lesson progress.
- Speaking updates progress and deletes local recordings after a confirmed upload.
- Writing drafts are restored per prompt, pending submissions appear in history, and offline completion queues progress.
- Dashboard responses are cached, and the configured daily word goal controls the dashboard target.
- Local study notifications support daily and weekday schedules, device timezone, Android/iOS permission requests, and reboot rescheduling on Android.
- Sound enablement and volume are applied by the shared audio player.
- The unavailable Japanese UI option was removed until a complete Japanese translation exists.
- Demo credentials were removed from registration and login forms.

## External release prerequisites

- Create Google OAuth clients for the final Android package/SHA and iOS bundle identifier, then add the iOS reversed client URL scheme.
- Replace the placeholder Android application ID and configure production signing.
- A backend profile update/avatar endpoint is required before device-local profile edits can sync across devices.

## Verification still required

- Execute the manual QA scripts on Android and iOS, including clean install, denied permissions, backend unavailable while Wi-Fi remains connected, package update/removal, and reconnect sync without duplicates.
- Verify notification delivery at the selected local time on physical devices.
- Run a signed release build after final OAuth identifiers and signing material are supplied.
