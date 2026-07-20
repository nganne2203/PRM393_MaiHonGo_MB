import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/media/audio_cache_service.dart';
import '../../../core/storage/local_database_service.dart';
import '../../lessons/models/lesson.dart';
import '../../lessons/repositories/lesson_repository.dart';
import '../../vocabulary/models/vocabulary.dart';
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
  final ApiClient apiClient;
  final AudioCacheService audioCacheService;

  OfflineRepository({
    required this.lessonRepository,
    required this.vocabularyRepository,
    required this.localDatabase,
    required this.apiClient,
    AudioCacheService? audioCacheService,
  }) : audioCacheService =
            audioCacheService ?? AudioCacheService(apiClient: apiClient);

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
      apiClient: apiClient,
    );
  }

  Future<List<Lesson>> getAvailableLessons() async {
    final result = await lessonRepository.getLessons();
    return result.data;
  }

  Future<void> downloadLesson(
    String lessonId, {
    CancelToken? cancelToken,
    void Function(double)? onProgress,
  }) async {
    onProgress?.call(0.02);
    try {
      final downloaded = await _downloadPackage(
        lessonId,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );
      if (downloaded) return;
    } catch (error) {
      if (!_isMissingPackageEndpoint(error)) rethrow;
    }

    await _downloadLegacyLesson(lessonId, onProgress: onProgress);
  }

  bool _isMissingPackageEndpoint(Object error) {
    if (error is! DioException) return false;
    return error.response?.statusCode == 404 ||
        error.response?.statusCode == 405;
  }

  Future<bool> _downloadPackage(
    String lessonId, {
    CancelToken? cancelToken,
    void Function(double)? onProgress,
  }) async {
    final response = await apiClient.dio.get(
      '/offline/packages/$lessonId/download',
      cancelToken: cancelToken,
    );
    onProgress?.call(0.15);
    final data = ApiEnvelope.unwrapData(asJsonMap(response.data));
    if (data is! Map) return false;
    final bundle = asJsonMap(data);
    final lessonJson = bundle['lesson'];
    final vocabularyJson = _mapList(bundle['vocabulary']);
    if (lessonJson is! Map || vocabularyJson.isEmpty) return false;

    final lesson = Lesson.fromJson(asJsonMap(lessonJson), downloaded: true);
    if (lesson.id.isEmpty) return false;
    final vocabulary = vocabularyJson
        .map((item) => Vocabulary.fromJson(item, lessonId: lessonId))
        .toList();
    final hydratedLesson = lesson.copyWith(
      vocabulary: vocabulary,
      vocabIds: vocabulary.map((item) => item.id).toList(),
      downloaded: true,
    );
    final listening = _mapList(bundle['listeningExercises']);
    final speaking = _mapList(bundle['speakingPrompts']);
    final writing = _mapList(bundle['writingPrompts']);

    await localDatabase.saveLessons([hydratedLesson]);
    await localDatabase.saveVocabulary(vocabulary, lessonId: lessonId);
    await localDatabase.savePracticeContent(
      kind: 'listening',
      lessonId: lessonId,
      items: listening,
    );
    await localDatabase.savePracticeContent(
      kind: 'speaking',
      lessonId: lessonId,
      items: speaking,
    );
    await localDatabase.savePracticeContent(
      kind: 'writing',
      lessonId: lessonId,
      items: writing,
    );
    onProgress?.call(0.3);

    final urls = <String>{
      ...vocabulary.map((item) => item.audioUrl),
      ...listening.map((item) => item['audioUrl']?.toString() ?? ''),
      ...speaking.map((item) => item['sampleAudioUrl']?.toString() ?? ''),
      ..._mapList(bundle['mediaAssets']).expand(_mediaUrls),
    }..removeWhere((url) => url.trim().isEmpty);
    var failedMedia = 0;
    var completedMedia = 0;
    for (final url in urls) {
      try {
        final localPath = await audioCacheService.cacheRemoteAudio(
          url,
          cancelToken: cancelToken,
        );
        await localDatabase.saveOfflineMedia(
          lessonId: lessonId,
          remoteUrl: url,
          localPath: localPath,
        );
      } catch (_) {
        if (cancelToken?.isCancelled == true) rethrow;
        failedMedia += 1;
      }
      completedMedia += 1;
      onProgress?.call(0.3 + (0.65 * completedMedia / urls.length));
    }

    final manifest = bundle['manifest'];
    final manifestJson = manifest is Map ? asJsonMap(manifest) : const {};
    final size = int.tryParse(
          (manifestJson['totalSize'] ?? manifestJson['estimatedSize'])
                  ?.toString() ??
              '',
        ) ??
        _estimateSize(hydratedLesson, vocabulary);
    await localDatabase.markDownloaded(
      lesson: hydratedLesson,
      size: size,
      status: failedMedia == 0 ? 'downloaded' : 'downloaded_partial',
    );
    onProgress?.call(1);
    return true;
  }

  Future<void> _downloadLegacyLesson(
    String lessonId, {
    void Function(double)? onProgress,
  }) async {
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
    onProgress?.call(0.5);
    await localDatabase.saveVocabulary(vocabulary, lessonId: lessonId);
    await localDatabase.markDownloaded(
      lesson: hydratedLesson,
      size: _estimateSize(hydratedLesson, vocabulary),
    );
    onProgress?.call(1);
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

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) => asJsonMap(item)).toList();
  }

  Iterable<String> _mediaUrls(Map<String, dynamic> asset) sync* {
    for (final key in const ['url', 'audioUrl', 'publicUrl', 'downloadUrl']) {
      final value = asset[key]?.toString() ?? '';
      if (value.isNotEmpty) yield value;
    }
  }
}
