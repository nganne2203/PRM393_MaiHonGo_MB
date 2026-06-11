import '../../../core/network/api_client.dart';
import '../../../core/network/content_result.dart';
import '../../../core/storage/local_database_service.dart';
import '../models/lesson.dart';

class LessonRepository {
  final ApiClient apiClient;
  final LocalDatabaseService localDatabase;

  const LessonRepository({
    required this.apiClient,
    required this.localDatabase,
  });

  Future<ContentResult<List<Lesson>>> getLessons() async {
    try {
      final response = await apiClient.dio.get('/lessons');
      final lessons = parseLessonListEnvelope(response.data);
      await localDatabase.saveLessons(lessons);
      final cached = await localDatabase.getLessons();
      return ContentResult(data: _mergeDownloaded(lessons, cached));
    } catch (error) {
      final cached = await localDatabase.getLessons();
      return ContentResult(
        data: cached,
        isOffline: cached.isNotEmpty,
        errorMessage: cached.isEmpty ? ApiClient.describeError(error) : null,
      );
    }
  }

  Future<ContentResult<Lesson?>> getLesson(String lessonId) async {
    try {
      final response = await apiClient.dio.get('/lessons/$lessonId');
      final lesson = parseLessonEnvelope(response.data);
      await localDatabase.saveLessons([lesson]);
      if (lesson.vocabulary.isNotEmpty) {
        await localDatabase.saveVocabulary(
          lesson.vocabulary,
          lessonId: lesson.id,
        );
      }
      final cachedLesson = await localDatabase.getLesson(lesson.id);
      return ContentResult(
        data: lesson.copyWith(downloaded: cachedLesson?.downloaded),
      );
    } catch (error) {
      final cached = await localDatabase.getLesson(lessonId);
      return ContentResult(
        data: cached,
        isOffline: cached != null,
        errorMessage: cached == null ? ApiClient.describeError(error) : null,
      );
    }
  }

  static List<Lesson> parseLessonListEnvelope(dynamic responseData) {
    final data = ApiEnvelope.unwrapData(asJsonMap(responseData));
    if (data is! List) {
      throw const ApiException('Backend did not return lessons.');
    }
    return data
        .whereType<Map>()
        .map((item) => Lesson.fromJson(asJsonMap(item)))
        .where((lesson) => lesson.id.isNotEmpty)
        .toList();
  }

  static Lesson parseLessonEnvelope(dynamic responseData) {
    final data = ApiEnvelope.unwrapData(asJsonMap(responseData));
    if (data is! Map) {
      throw const ApiException('Backend did not return a lesson.');
    }
    return Lesson.fromJson(asJsonMap(data));
  }

  List<Lesson> _mergeDownloaded(List<Lesson> fresh, List<Lesson> cached) {
    final cachedById = {for (final lesson in cached) lesson.id: lesson};
    return fresh
        .map((lesson) => lesson.copyWith(
              downloaded: cachedById[lesson.id]?.downloaded,
            ))
        .toList();
  }
}
