import '../../../core/storage/local_database_service.dart';
import '../../../core/storage/local_models.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../bookmarks/models/bookmark.dart';
import '../../bookmarks/repositories/bookmark_repository.dart';
import '../../progress/models/progress_models.dart';
import '../../progress/repositories/progress_repository.dart';
import '../../settings/repositories/app_preferences_repository.dart';
import '../models/profile_summary.dart';
import 'profile_preferences_repository.dart';

class ProfileRepository {
  final AuthRepository authRepository;
  final BookmarkRepository bookmarkRepository;
  final ProgressRepository progressRepository;
  final LocalDatabaseService localDatabase;
  final AppPreferencesRepository preferencesRepository;
  final ProfilePreferencesRepository profilePreferencesRepository;

  const ProfileRepository({
    required this.authRepository,
    required this.bookmarkRepository,
    required this.progressRepository,
    required this.localDatabase,
    required this.preferencesRepository,
    required this.profilePreferencesRepository,
  });

  Future<ProfileSummary> getProfile(UserModel? fallbackUser) async {
    final user = await _loadUser(fallbackUser);
    final settings = await preferencesRepository.getSettings();
    final editableProfile = await profilePreferencesRepository.getProfile();
    final bookmarks = await _loadBookmarks();
    final progress = await _loadProgress();
    final lessons = await _orEmpty(localDatabase.getLessons);
    final vocabulary = await _orEmpty(localDatabase.getVocabulary);
    final packages = await _orEmpty(localDatabase.getContentPackages);
    final flashcards = await _orEmpty(localDatabase.getFlashcardSessionResults);

    final learnedVocabularyIds = <String>{
      for (final result in flashcards) ...result.learnedVocabularyIds,
    };
    final progressWordEstimate = progress.fold<int>(
      0,
      (sum, item) => sum + item.lastViewedVocabIndex.clamp(0, 10000).toInt(),
    );
    final learnedWords = [
      learnedVocabularyIds.length,
      progressWordEstimate,
    ].reduce((a, b) => a > b ? a : b);

    final completedLessonIds = {
      for (final item in progress)
        if (item.completed && item.lessonId.isNotEmpty) item.lessonId,
    };
    final activityDates = _activityDates(progress, flashcards, bookmarks);
    final totalXp = _totalXp(
      progress: progress,
      learnedWords: learnedWords,
      completedLessons: completedLessonIds.length,
      flashcardSessions: flashcards.length,
    );

    return ProfileSummary(
      user: user,
      streakDays: _streakDays(activityDates),
      learnedWords: learnedWords,
      savedWords: bookmarks.length,
      completedLessons: completedLessonIds.length,
      totalLessons: _max(lessons.length, progress.length),
      totalVocabulary: _max(vocabulary.length, bookmarks.length),
      downloadedLessons: packages.length,
      totalXp: totalXp,
      level: (totalXp ~/ 250) + 1,
      flashcardSessions: flashcards.length,
      weeklyCompletedDays: _weeklyCompletedDays(activityDates),
      weeklyGoalDays: settings.weeklyGoalDays,
      lastActivityAt: _latestActivityAt(activityDates),
      displayNameOverride: editableProfile.name,
      avatarOverride: editableProfile.avatarPath,
      birthday: editableProfile.birthday,
      gender: editableProfile.gender,
    );
  }

  Future<EditableProfile> saveEditableProfile(EditableProfile profile) {
    return profilePreferencesRepository.saveProfile(profile);
  }

  Future<UserModel> _loadUser(UserModel? fallbackUser) async {
    try {
      return await authRepository.me();
    } catch (_) {
      return fallbackUser ?? ProfileSummary.guest();
    }
  }

  Future<List<Bookmark>> _loadBookmarks() async {
    try {
      return await bookmarkRepository.getBookmarks();
    } catch (_) {
      return _orEmpty(localDatabase.getBookmarks);
    }
  }

  Future<List<ProgressModel>> _loadProgress() async {
    try {
      return await progressRepository.getProgress();
    } catch (_) {
      return const [];
    }
  }

  Future<List<T>> _orEmpty<T>(Future<List<T>> Function() read) async {
    try {
      return await read();
    } catch (_) {
      return const [];
    }
  }

  List<DateTime> _activityDates(
    List<ProgressModel> progress,
    List<LocalFlashcardSessionResult> flashcards,
    List<Bookmark> bookmarks,
  ) {
    return [
      for (final item in progress)
        if (item.lastPracticeAt != null) item.lastPracticeAt!,
      for (final item in flashcards) item.completedAt,
      for (final item in bookmarks)
        if (item.createdAt != null) item.createdAt!,
    ];
  }

  int _totalXp({
    required List<ProgressModel> progress,
    required int learnedWords,
    required int completedLessons,
    required int flashcardSessions,
  }) {
    final progressScore = progress.fold<int>(
        0, (sum, item) => sum + item.score.clamp(0, 10000).toInt());
    return progressScore +
        learnedWords * 10 +
        completedLessons * 25 +
        flashcardSessions * 5;
  }

  int _streakDays(List<DateTime> activityDates) {
    final dates = _dateSet(activityDates);
    if (dates.isEmpty) return 0;

    var cursor = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    var streak = 0;
    while (dates.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _weeklyCompletedDays(List<DateTime> activityDates) {
    final today = _dateOnly(DateTime.now());
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    return _dateSet(activityDates)
        .where((date) => !date.isBefore(startOfWeek) && !date.isAfter(today))
        .length;
  }

  DateTime? _latestActivityAt(List<DateTime> activityDates) {
    if (activityDates.isEmpty) return null;
    return activityDates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  Set<DateTime> _dateSet(List<DateTime> dates) {
    return dates.map(_dateOnly).toSet();
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int _max(int a, int b) => a > b ? a : b;
}
