# Manual QA Scripts

Run these scripts against the mobile app with a seeded backend when possible.

## Auth and Onboarding

1. Clear app data.
2. Launch app and confirm onboarding appears.
3. Tap Skip and confirm login appears.
4. Restart app and confirm onboarding does not reappear.
5. Register or login with a test learner.
6. Restart app and confirm main shell opens.
7. Logout and confirm the app returns to login.

Expected result: onboarding/session routing persists and logout clears the session.

## Settings

1. Open Profile, then Settings.
2. Toggle Dark Mode, Notifications, and Sound Effects.
3. Navigate away and return to Settings.
4. Restart app and open Settings again.
5. Open Offline Downloads and Privacy & Security rows.

Expected result: toggles persist, and navigation rows open the expected screens.

## Bookmarks and Saved Words

1. Open a lesson with vocabulary.
2. Bookmark two vocabulary items.
3. Open Saved Words and confirm both appear.
4. Search by kanji, kana, romaji, and Vietnamese meaning.
5. Remove one saved word.
6. Simulate API failure or turn off network after bookmarks have cached.
7. Reopen Saved Words.

Expected result: online data is used first, cached bookmarks appear offline, and remove is optimistic with failure recovery.

## Lessons, Vocabulary, and Flashcards

1. Open Lessons and confirm loading, empty, or lesson cards display cleanly.
2. Open a lesson and verify vocabulary search and tag filters.
3. Tap unavailable audio and confirm a friendly message.
4. Start flashcards, answer known and unknown cards, and reach summary.
5. Repeat with network disabled for a downloaded lesson.

Expected result: shared state widgets appear consistently, and practice state is not lost offline.

## Offline Downloads and Sync

1. Open Settings, then Offline Downloads.
2. Download an offline-ready lesson.
3. Disable network.
4. Open downloaded lesson, vocabulary, and flashcards.
5. Make progress and bookmark changes.
6. Re-enable network and trigger refresh/sync.

Expected result: downloaded content opens offline, pending changes survive, and sync does not duplicate attempts.

## Listening, Speaking, and Writing

1. Open each practice mode from Home or a lesson.
2. Confirm empty/loading/error states when no prompts exist.
3. Complete one listening answer.
4. Record and submit one speaking attempt.
5. Submit one writing answer and open history.
6. Repeat with network disabled where supported.

Expected result: each practice mode has a recoverable state, stores attempts locally when needed, and displays history/feedback when available.
