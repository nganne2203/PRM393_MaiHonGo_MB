import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/bookmarks/repositories/bookmark_repository.dart';

void main() {
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
}
