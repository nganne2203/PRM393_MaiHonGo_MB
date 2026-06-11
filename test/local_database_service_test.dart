import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/lessons/models/lesson.dart';
import 'package:maihongo/features/vocabulary/models/vocabulary.dart';

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Isar saves and loads lessons, vocabulary, and downloads', () async {
    final database = await openTestDatabase('local_db_test');
    addTearDown(() => database.isar.close(deleteFromDisk: true));

    const lesson = Lesson(
      id: 'lesson-1',
      title: 'JLPT N5',
      category: 'N5',
      description: 'Basics',
      isOfflineReady: true,
      downloadable: true,
      version: 2,
      size: 2048,
      vocabIds: ['vocab-1'],
    );
    const vocabulary = Vocabulary(
      id: 'vocab-1',
      word: '猫',
      hiragana: 'ねこ',
      romaji: 'neko',
      meaningVi: 'Mèo',
      tags: ['N5'],
      examples: [VocabularyExample(jp: '猫です', vi: 'La con mèo')],
      lessonId: 'lesson-1',
    );

    await database.saveLessons([lesson]);
    await database.saveVocabulary([vocabulary], lessonId: 'lesson-1');
    await database.markDownloaded(lesson: lesson);

    final lessons = await database.getLessons();
    final vocabularyList = await database.getVocabulary(lessonId: 'lesson-1');
    final packages = await database.getContentPackages();

    expect(lessons.single.downloaded, isTrue);
    expect(vocabularyList.single.word, '猫');
    expect(vocabularyList.single.examples.single.vi, 'La con mèo');
    expect(packages.single.lessonId, 'lesson-1');
  });
}
