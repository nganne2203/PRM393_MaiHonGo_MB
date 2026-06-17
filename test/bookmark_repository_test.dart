import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/bookmarks/repositories/bookmark_repository.dart';

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BookmarkRepository parses populated bookmark envelope', () {
    final bookmarks = BookmarkRepository.parseBookmarkListEnvelope({
      'success': true,
      'message': 'ok',
      'data': [
        {
          '_id': 'bookmark-1',
          'vocabId': {
            '_id': 'vocab-1',
            'word': '水',
            'hiragana': 'みず',
            'romaji': 'mizu',
            'meaningVi': 'nước',
            'tags': ['N5'],
            'examples': [],
          },
          'createdAt': '2026-06-12T00:00:00.000Z',
        },
      ],
      'pagination': null,
    });

    expect(bookmarks, hasLength(1));
    expect(bookmarks.first.vocabId, 'vocab-1');
    expect(bookmarks.first.vocabulary?.word, '水');
  });

  test('BookmarkRepository falls back to cached bookmarks', () async {
    final database = await openTestDatabase('bookmark_cache_test');
    addTearDown(() => database.isar.close(deleteFromDisk: true));

    var failRemote = false;
    final client = fakeApiClient((options) async {
      if (failRemote) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'offline',
        );
      }

      return jsonResponse({
        'success': true,
        'message': 'ok',
        'data': [
          {
            '_id': 'bookmark-1',
            'vocabId': {
              '_id': 'vocab-1',
              'word': '水',
              'hiragana': 'みず',
              'romaji': 'mizu',
              'meaningVi': 'nước',
              'tags': ['N5'],
              'examples': [],
            },
            'createdAt': '2026-06-12T00:00:00.000Z',
          },
        ],
        'pagination': null,
      });
    });
    final repository = BookmarkRepository(
      apiClient: client,
      localDatabase: Future.value(database),
    );

    final remote = await repository.getBookmarks();
    expect(remote.single.vocabulary?.word, '水');

    failRemote = true;
    final cached = await repository.getBookmarks();
    final cachedIds = await repository.getBookmarkedVocabIds();

    expect(cached.single.vocabId, 'vocab-1');
    expect(cached.single.vocabulary?.meaningVi, 'nước');
    expect(cachedIds, contains('vocab-1'));
  });
}
