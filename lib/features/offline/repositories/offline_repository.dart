import '../../../core/network/api_client.dart';
import '../../../core/storage/local_database_service.dart';
import '../../lessons/models/lesson.dart';
import '../../lessons/repositories/lesson_repository.dart';
import '../../vocabulary/repositories/vocabulary_repository.dart';

class DownloadedLesson {
  final Lesson lesson;
  final int size;
  final DateTime downloadedAt;
  final String status;

  const DownloadedLesson({
    required this.lesson,
    required this.size,
    required this.downloadedAt,
    required this.status,
  });
}

class OfflineRepository {
  final LessonRepository lessonRepository;
  final VocabularyRepository vocabularyRepository;
  final LocalDatabaseService localDatabase;

  const OfflineRepository({
    required this.lessonRepository,
    required this.vocabularyRepository,
    required this.localDatabase,
  });

  factory OfflineRepository.withDependencies({
    required ApiClient apiClient,
    required LocalDatabaseService localDatabase,
  }) {
    return OfflineRepository(
      lessonRepository: LessonRepository(
        apiClient: apiClient,
        localDatabase: localDatabase,
      ),
      vocabularyRepository: VocabularyRepository(
        apiClient: apiClient,
        localDatabase: localDatabase,
      ),
      localDatabase: localDatabase,
    );
  }

  Future<List<Lesson>> getAvailableLessons() async {
    final result = await lessonRepository.getLessons();
    return result.data;
  }

  Future<void> downloadLesson(String lessonId) async {
    final lessonResult = await lessonRepository.getLesson(lessonId);
    final lesson = lessonResult.data;
    if (lesson == null) {
      throw const ApiException('Lesson is not available for download.');
    }

    final vocabularyResult = await vocabularyRepository.getByLessonId(lessonId);
    final vocabulary = vocabularyResult.data;
    if (vocabulary.isEmpty) {
      throw const ApiException('Lesson vocabulary is not available offline.');
    }

    final hydratedLesson = lesson.copyWith(
      vocabulary: vocabulary,
      vocabIds: vocabulary.map((item) => item.id).toList(),
      downloaded: true,
    );
    await localDatabase.saveLessons([hydratedLesson]);
    await localDatabase.saveVocabulary(vocabulary, lessonId: lessonId);
    await localDatabase.markDownloaded(
      lesson: hydratedLesson,
      size: _estimateSize(hydratedLesson, vocabulary),
    );
  }

  Future<void> removeDownloadedLesson(String lessonId) {
    return localDatabase.removeDownloaded(lessonId);
  }

  Future<List<DownloadedLesson>> getDownloadedLessons() async {
    final packages = await localDatabase.getContentPackages();
    final lessons = await localDatabase.getLessons();
    final lessonsById = {for (final lesson in lessons) lesson.id: lesson};

    return packages
        .map((package) {
          final lesson = lessonsById[package.lessonId];
          if (lesson == null) return null;
          return DownloadedLesson(
            lesson: lesson,
            size: package.size,
            downloadedAt: package.downloadedAt,
            status: package.status ?? 'downloaded',
          );
        })
        .whereType<DownloadedLesson>()
        .toList();
  }

  int _estimateSize(Lesson lesson, List<dynamic> vocabulary) {
    if (lesson.size > 0) return lesson.size;
    return 1024 + vocabulary.length * 512;
  }
}
