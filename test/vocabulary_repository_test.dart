import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/vocabulary/models/vocabulary.dart';
import 'package:maihongo/features/vocabulary/repositories/vocabulary_repository.dart';

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('VocabularyRepository parses backend response envelope', () {
    final vocabulary = VocabularyRepository.parseVocabularyListEnvelope({
      'success': true,
      'message': 'ok',
      'pagination': null,
      'data': [
        {
          '_id': 'vocab-1',
          'kanji': '水',
          'hiragana': 'みず',
          'romaji': 'mizu',
          'meaningVi': 'Nước',
          'examples': [
            {'jp': '水を飲みます', 'vi': 'Tôi uống nước'}
          ],
          'tags': ['N5'],
        }
      ],
    });

    expect(vocabulary.single.word, '水');
    expect(vocabulary.single.meaningVi, 'Nước');
    expect(vocabulary.single.tags, ['N5']);
  });

  test('VocabularyRepository searches cached vocabulary when API fails',
      () async {
    final database = await openTestDatabase('vocab_repo_test');
    addTearDown(() => database.isar.close(deleteFromDisk: true));
    await database.saveVocabulary([
      const Vocabulary(
        id: 'vocab-1',
        word: '猫',
        hiragana: 'ねこ',
        romaji: 'neko',
        meaningVi: 'Mèo',
        tags: ['N5'],
        examples: [],
      ),
      const Vocabulary(
        id: 'vocab-2',
        word: '水',
        hiragana: 'みず',
        romaji: 'mizu',
        meaningVi: 'Nước',
        tags: ['N5'],
        examples: [],
      ),
    ]);

    final repository = VocabularyRepository(
      apiClient: fakeApiClient((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'offline',
        );
      }),
      localDatabase: database,
    );

    final result = await repository.searchVocabulary('neko');

    expect(result.isOffline, isTrue);
    expect(result.data.single.word, '猫');
  });
}
