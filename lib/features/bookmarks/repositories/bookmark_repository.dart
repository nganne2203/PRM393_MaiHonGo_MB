import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_database_service.dart';
import '../../vocabulary/models/vocabulary.dart';
import '../models/bookmark.dart';

class BookmarkRepository {
  final ApiClient apiClient;
  final Future<LocalDatabaseService>? _localDatabase;

  BookmarkRepository({
    ApiClient? apiClient,
    Future<LocalDatabaseService>? localDatabase,
  })  : apiClient = apiClient ?? ApiClient(),
        _localDatabase = localDatabase ?? LocalDatabaseService.open();

  Future<List<Bookmark>> getBookmarks() async {
    try {
      final response = await apiClient.dio.get('/bookmarks');
      final bookmarks = parseBookmarkListEnvelope(asJsonMap(response.data));
      await _saveCachedBookmarks(bookmarks);
      return bookmarks;
    } catch (error) {
      final cached = await _readCachedBookmarks();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<Bookmark> addBookmark(
    String vocabId, {
    Vocabulary? vocabulary,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/bookmarks',
        data: {'vocabId': vocabId},
      );
      final bookmark = parseBookmarkEnvelope(asJsonMap(response.data));
      await _saveCachedBookmark(bookmark);
      return bookmark;
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      final pending = Bookmark(
        id: 'pending-$vocabId',
        vocabId: vocabId,
        vocabulary: vocabulary,
        createdAt: DateTime.now(),
      );
      final database = await _openCache();
      await database?.saveBookmark(pending);
      await database?.enqueueSyncOperation(
        operationType: 'bookmark',
        dedupeKey: 'bookmark-$vocabId',
        payload: {'vocabId': vocabId, 'action': 'add'},
      );
      return pending;
    }
  }

  Future<void> removeBookmark(String vocabId) async {
    try {
      await apiClient.dio.delete('/bookmarks/$vocabId');
      await _removeCachedBookmark(vocabId);
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      final database = await _openCache();
      await database?.removeBookmark(vocabId);
      await database?.enqueueSyncOperation(
        operationType: 'bookmark',
        dedupeKey: 'bookmark-$vocabId',
        payload: {'vocabId': vocabId, 'action': 'remove'},
      );
    }
  }

  Future<int> syncPendingOperations() async {
    final database = await _openCache();
    if (database == null) return 0;
    final operations =
        await database.getSyncOperations(operationType: 'bookmark');
    var synced = 0;
    for (final operation in operations) {
      final id = operation['id'];
      final payload = operation['payload'];
      if (id is! int || payload is! Map) continue;
      final vocabId = payload['vocabId']?.toString() ?? '';
      final action = payload['action']?.toString() ?? '';
      if (vocabId.isEmpty) {
        await database.deleteSyncOperation(id);
        continue;
      }
      try {
        if (action == 'add') {
          final response = await apiClient.dio.post(
            '/bookmarks',
            data: {'vocabId': vocabId},
          );
          await database.saveBookmark(
            parseBookmarkEnvelope(asJsonMap(response.data)),
          );
        } else {
          await apiClient.dio.delete('/bookmarks/$vocabId');
          await database.removeBookmark(vocabId);
        }
        await database.deleteSyncOperation(id);
        synced += 1;
      } catch (error) {
        await database.markSyncOperationFailed(id, error);
      }
    }
    return synced;
  }

  Future<Set<String>> getBookmarkedVocabIds() async {
    try {
      final bookmarks = await getBookmarks();
      return bookmarks
          .map((item) => item.vocabId)
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      final cached = await _readCachedBookmarkIds();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  static Bookmark parseBookmarkEnvelope(Map<String, dynamic> envelope) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! Map) {
      throw const ApiException('Bookmark response is invalid.');
    }
    return Bookmark.fromJson(asJsonMap(data));
  }

  static List<Bookmark> parseBookmarkListEnvelope(
    Map<String, dynamic> envelope,
  ) {
    final data = ApiEnvelope.unwrapData(envelope);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => Bookmark.fromJson(asJsonMap(item)))
        .toList();
  }

  Future<void> _saveCachedBookmarks(List<Bookmark> bookmarks) async {
    final database = await _openCache();
    if (database == null) return;
    await database.saveBookmarks(bookmarks);
  }

  Future<void> _saveCachedBookmark(Bookmark bookmark) async {
    final database = await _openCache();
    if (database == null) return;
    await database.saveBookmark(bookmark);
  }

  Future<void> _removeCachedBookmark(String vocabId) async {
    final database = await _openCache();
    if (database == null) return;
    await database.removeBookmark(vocabId);
  }

  Future<List<Bookmark>> _readCachedBookmarks() async {
    final database = await _openCache();
    if (database == null) return const [];
    return database.getBookmarks();
  }

  Future<Set<String>> _readCachedBookmarkIds() async {
    final database = await _openCache();
    if (database == null) return const {};
    return database.getBookmarkedVocabIds();
  }

  Future<LocalDatabaseService?> _openCache() async {
    try {
      return await _localDatabase;
    } catch (_) {
      return null;
    }
  }
}

bool _isRetryable(Object error) {
  if (error is! DioException) return false;
  return error.response == null ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout;
}
