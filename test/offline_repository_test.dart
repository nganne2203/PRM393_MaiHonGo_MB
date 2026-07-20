import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/offline/repositories/offline_repository.dart';

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('OfflineRepository downloads lesson content into SQLite', () async {
    final database = await openTestDatabase('offline_repo_test');
    addTearDown(() => database.close(deleteFromDisk: true));

    final apiClient = fakeApiClient((options) async {
      if (options.path == '/lessons/lesson-1') {
        return jsonResponse({
          'success': true,
          'message': 'ok',
          'pagination': null,
          'data': {
            '_id': 'lesson-1',
            'title': 'Animals',
            'category': 'N5',
            'description': 'Animal words',
            'isOfflineReady': true,
            'version': 1,
            'assetSize': 4096,
            'vocabIds': [
              {
                '_id': 'vocab-1',
                'kanji': '猫',
                'hiragana': 'ねこ',
                'romaji': 'neko',
                'meaningVi': 'Mèo',
                'examples': [],
                'tags': ['N5'],
              }
            ],
          },
        });
      }
      if (options.path == '/vocabulary') {
        return jsonResponse({
          'success': true,
          'message': 'ok',
          'pagination': null,
          'data': [],
        });
      }
      return jsonResponse({'success': true, 'message': 'ok', 'data': []});
    });

    final repository = OfflineRepository.withDependencies(
      apiClient: apiClient,
      localDatabase: database,
    );

    await repository.downloadLesson('lesson-1');
    final downloads = await repository.getDownloadedLessons();
    final vocabulary = await database.getVocabulary(lessonId: 'lesson-1');

    expect(downloads.single.lesson.title, 'Animals');
    expect(vocabulary.single.word, '猫');
  });

  test('OfflineRepository stores practice content from package bundle',
      () async {
    final database = await openTestDatabase('offline_package_test');
    addTearDown(() => database.close(deleteFromDisk: true));

    final apiClient = fakeApiClient((options) async {
      if (options.path == '/offline/packages/lesson-2/download') {
        return jsonResponse({
          'success': true,
          'message': 'ok',
          'data': {
            'manifest': {'totalSize': 8192},
            'lesson': {
              '_id': 'lesson-2',
              'title': 'Practice pack',
              'category': 'N5',
              'description': 'Complete offline content',
              'isOfflineReady': true,
              'version': 3,
            },
            'vocabulary': [
              {
                '_id': 'vocab-2',
                'kanji': '水',
                'hiragana': 'みず',
                'meaningVi': 'nước',
                'examples': [],
                'tags': ['N5'],
              }
            ],
            'listeningExercises': [
              {
                '_id': 'listening-1',
                'lessonId': 'lesson-2',
                'questionText': 'Choose water',
                'choices': ['水', '火'],
                'correctAnswer': '水',
              }
            ],
            'speakingPrompts': [
              {
                '_id': 'speaking-1',
                'lessonId': 'lesson-2',
                'promptText': 'Say water',
                'expectedText': '水',
              }
            ],
            'writingPrompts': [
              {
                '_id': 'writing-1',
                'lessonId': 'lesson-2',
                'promptText': 'Write water',
              }
            ],
            'mediaAssets': [],
          },
        });
      }
      throw StateError('Unexpected request: ${options.path}');
    });
    final repository = OfflineRepository.withDependencies(
      apiClient: apiClient,
      localDatabase: database,
    );
    final progress = <double>[];

    await repository.downloadLesson(
      'lesson-2',
      onProgress: progress.add,
    );

    expect(
      await database.getPracticeContent(
        kind: 'listening',
        lessonId: 'lesson-2',
      ),
      hasLength(1),
    );
    expect(
      await database.getPracticeContent(
        kind: 'speaking',
        lessonId: 'lesson-2',
      ),
      hasLength(1),
    );
    expect(
      await database.getPracticeContent(
        kind: 'writing',
        lessonId: 'lesson-2',
      ),
      hasLength(1),
    );
    expect((await repository.getDownloadedLessons()).single.size, 8192);
    expect(progress.first, greaterThanOrEqualTo(0));
    expect(progress.last, 1);

    await repository.removeDownloadedLesson('lesson-2');
    expect(await database.getVocabulary(lessonId: 'lesson-2'), isEmpty);
    expect(
      await database.getPracticeContent(
        kind: 'listening',
        lessonId: 'lesson-2',
      ),
      isEmpty,
    );
  });
}
