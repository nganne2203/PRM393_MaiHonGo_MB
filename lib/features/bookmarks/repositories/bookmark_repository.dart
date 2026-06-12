import '../../../core/network/api_client.dart';
import '../models/bookmark.dart';

class BookmarkRepository {
  final ApiClient apiClient;

  BookmarkRepository({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient();

  Future<List<Bookmark>> getBookmarks() async {
    final response = await apiClient.dio.get('/bookmarks');
    return parseBookmarkListEnvelope(asJsonMap(response.data));
  }

  Future<Bookmark> addBookmark(String vocabId) async {
    final response = await apiClient.dio.post(
      '/bookmarks',
      data: {'vocabId': vocabId},
    );
    return parseBookmarkEnvelope(asJsonMap(response.data));
  }

  Future<void> removeBookmark(String vocabId) async {
    await apiClient.dio.delete('/bookmarks/$vocabId');
  }

  Future<Set<String>> getBookmarkedVocabIds() async {
    final bookmarks = await getBookmarks();
    return bookmarks
        .map((item) => item.vocabId)
        .where((id) => id.isNotEmpty)
        .toSet();
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
}
