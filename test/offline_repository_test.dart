import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/offline/repositories/offline_repository.dart';

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('OfflineRepository downloads lesson content into Isar', () async {
    final database = await openTestDatabase('offline_repo_test');
    addTearDown(() => database.isar.close(deleteFromDisk: true));

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
}
