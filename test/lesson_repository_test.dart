import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/lessons/models/lesson.dart';
import 'package:maihongo/features/lessons/repositories/lesson_repository.dart';

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LessonRepository parses backend response envelope', () {
    final lessons = LessonRepository.parseLessonListEnvelope({
      'success': true,
      'message': 'ok',
      'pagination': null,
      'data': [
        {
          '_id': 'lesson-1',
          'title': 'JLPT N5',
          'category': 'N5',
          'description': 'Basics',
          'isOfflineReady': true,
          'vocabIds': ['vocab-1'],
        }
      ],
    });

    expect(lessons.single.id, 'lesson-1');
    expect(lessons.single.title, 'JLPT N5');
    expect(lessons.single.isOfflineReady, isTrue);
  });

  test('LessonRepository falls back to cached lessons when API fails',
      () async {
    final database = await openTestDatabase('lesson_repo_test');
    addTearDown(() => database.isar.close(deleteFromDisk: true));
    await database.saveLessons([
      const Lesson(
        id: 'lesson-1',
        title: 'Cached Lesson',
        category: 'N5',
        description: 'Stored locally',
        isOfflineReady: true,
        downloadable: true,
        version: 1,
        size: 0,
        vocabIds: [],
      ),
    ]);

    final repository = LessonRepository(
      apiClient: fakeApiClient((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'offline',
        );
      }),
      localDatabase: database,
    );

    final result = await repository.getLessons();

    expect(result.isOffline, isTrue);
    expect(result.data.single.title, 'Cached Lesson');
  });
}
