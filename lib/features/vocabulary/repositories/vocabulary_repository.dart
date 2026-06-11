import '../../../core/network/api_client.dart';
import '../../../core/network/content_result.dart';
import '../../../core/storage/local_database_service.dart';
import '../../lessons/repositories/lesson_repository.dart';
import '../models/vocabulary.dart';

class VocabularyRepository {
  final ApiClient apiClient;
  final LocalDatabaseService localDatabase;

  const VocabularyRepository({
    required this.apiClient,
    required this.localDatabase,
  });

  Future<ContentResult<List<Vocabulary>>> getVocabulary() {
    return _getVocabulary();
  }

  Future<ContentResult<List<Vocabulary>>> searchVocabulary(String query) {
    return _getVocabulary(query: query);
  }

  Future<ContentResult<List<Vocabulary>>> filterByTag(String tag) {
    return _getVocabulary(tag: tag);
  }

  Future<ContentResult<List<Vocabulary>>> getByLessonId(String lessonId) async {
    try {
      final lessonResponse = await apiClient.dio.get('/lessons/$lessonId');
      final lesson = LessonRepository.parseLessonEnvelope(lessonResponse.data);
      await localDatabase.saveLessons([lesson]);
      if (lesson.vocabulary.isNotEmpty) {
        await localDatabase.saveVocabulary(
          lesson.vocabulary,
          lessonId: lesson.id,
        );
        return ContentResult(data: lesson.vocabulary);
      }

      final allVocabulary = await _getVocabulary();
      final idSet = lesson.vocabIds.toSet();
      final data = allVocabulary.data
          .where((vocab) => idSet.contains(vocab.id))
          .map((vocab) => vocab.copyWith(lessonId: lesson.id))
          .toList();
      await localDatabase.saveVocabulary(data, lessonId: lesson.id);
      return ContentResult(data: data, isOffline: allVocabulary.isOffline);
    } catch (error) {
      final cachedByLesson = await localDatabase.getVocabulary(
        lessonId: lessonId,
      );
      if (cachedByLesson.isNotEmpty) {
        return ContentResult(data: cachedByLesson, isOffline: true);
      }

      final lesson = await localDatabase.getLesson(lessonId);
      final cachedByIds = lesson == null
          ? <Vocabulary>[]
          : await localDatabase.getVocabularyByIds(lesson.vocabIds);
      return ContentResult(
        data: cachedByIds,
        isOffline: cachedByIds.isNotEmpty,
        errorMessage:
            cachedByIds.isEmpty ? ApiClient.describeError(error) : null,
      );
    }
  }

  Future<ContentResult<List<Vocabulary>>> _getVocabulary({
    String? query,
    String? tag,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/vocabulary',
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (tag != null && tag.trim().isNotEmpty) 'tag': tag.trim(),
        },
      );
      final vocabulary = parseVocabularyListEnvelope(response.data);
      await localDatabase.saveVocabulary(vocabulary);
      return ContentResult(data: vocabulary);
    } catch (error) {
      final cached = await localDatabase.getVocabulary();
      final filtered = _filterLocal(cached, query: query, tag: tag);
      return ContentResult(
        data: filtered,
        isOffline: filtered.isNotEmpty,
        errorMessage: filtered.isEmpty ? ApiClient.describeError(error) : null,
      );
    }
  }

  static List<Vocabulary> parseVocabularyListEnvelope(dynamic responseData) {
    final data = ApiEnvelope.unwrapData(asJsonMap(responseData));
    if (data is! List) {
      throw const ApiException('Backend did not return vocabulary.');
    }
    return data
        .whereType<Map>()
        .map((item) => Vocabulary.fromJson(asJsonMap(item)))
        .where((vocab) => vocab.id.isNotEmpty)
        .toList();
  }

  List<Vocabulary> _filterLocal(
    List<Vocabulary> cached, {
    String? query,
    String? tag,
  }) {
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    final normalizedTag = tag?.trim().toLowerCase() ?? '';

    return cached.where((vocab) {
      final matchesQuery = normalizedQuery.isEmpty ||
          vocab.word.toLowerCase().contains(normalizedQuery) ||
          vocab.hiragana.toLowerCase().contains(normalizedQuery) ||
          vocab.romaji.toLowerCase().contains(normalizedQuery) ||
          vocab.meaningVi.toLowerCase().contains(normalizedQuery);
      final matchesTag = normalizedTag.isEmpty ||
          vocab.tags.any((item) => item.toLowerCase() == normalizedTag);
      return matchesQuery && matchesTag;
    }).toList();
  }
}
