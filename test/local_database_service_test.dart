import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/lessons/models/lesson.dart';
import 'package:maihongo/features/vocabulary/models/vocabulary.dart';

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SQLite saves and loads lessons, vocabulary, and downloads', () async {
    final database = await openTestDatabase('local_db_test');
    addTearDown(() => database.close(deleteFromDisk: true));

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

  test('SQLite persists resume state, drafts, and deduplicated sync work',
      () async {
    final database = await openTestDatabase('local_state_test');
    addTearDown(() => database.close(deleteFromDisk: true));

    await database.saveFlashcardResume(
      sessionKey: 'lesson:lesson-1',
      currentIndex: 3,
      statuses: {'vocab-1': 'learned'},
    );
    await database.saveWritingDraft(
      promptId: 'prompt-1',
      lessonId: 'lesson-1',
      answerText: 'わたしは学生です。',
    );
    await database.enqueueSyncOperation(
      operationType: 'bookmark',
      dedupeKey: 'bookmark-vocab-1',
      payload: {'vocabId': 'vocab-1', 'action': 'add'},
    );
    await database.enqueueSyncOperation(
      operationType: 'bookmark',
      dedupeKey: 'bookmark-vocab-1',
      payload: {'vocabId': 'vocab-1', 'action': 'remove'},
    );

    final resume = await database.getFlashcardResume('lesson:lesson-1');
    final operations = await database.getSyncOperations(
      operationType: 'bookmark',
    );
    expect(resume?['currentIndex'], 3);
    expect((resume?['statuses'] as Map)['vocab-1'], 'learned');
    expect(await database.getWritingDraft('prompt-1'), 'わたしは学生です。');
    expect(operations, hasLength(1));
    expect((operations.single['payload'] as Map)['action'], 'remove');
  });
}
