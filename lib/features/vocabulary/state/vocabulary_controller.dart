import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/content_result.dart';
import '../../../core/state/content_state.dart';
import '../../../core/storage/local_database_provider.dart';
import '../../auth/state/auth_state.dart';
import '../models/vocabulary.dart';
import '../repositories/vocabulary_repository.dart';

class VocabularyState {
  final ContentStatus status;
  final List<Vocabulary> vocabulary;
  final String query;
  final String tag;
  final String? lessonId;
  final String? message;

  const VocabularyState({
    required this.status,
    required this.vocabulary,
    this.query = '',
    this.tag = 'All',
    this.lessonId,
    this.message,
  });

  const VocabularyState.initial()
      : status = ContentStatus.initial,
        vocabulary = const [],
        query = '',
        tag = 'All',
        lessonId = null,
        message = null;

  VocabularyState copyWith({
    ContentStatus? status,
    List<Vocabulary>? vocabulary,
    String? query,
    String? tag,
    String? lessonId,
    bool clearLessonId = false,
    String? message,
    bool clearMessage = false,
  }) {
    return VocabularyState(
      status: status ?? this.status,
      vocabulary: vocabulary ?? this.vocabulary,
      query: query ?? this.query,
      tag: tag ?? this.tag,
      lessonId: clearLessonId ? null : lessonId ?? this.lessonId,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

final vocabularyRepositoryProvider =
    FutureProvider<VocabularyRepository>((ref) async {
  return VocabularyRepository(
    apiClient: ref.watch(apiClientProvider),
    localDatabase: await ref.watch(localDatabaseProvider.future),
  );
});

final vocabularyProvider =
    StateNotifierProvider<VocabularyController, VocabularyState>((ref) {
  return VocabularyController(ref);
});

class VocabularyController extends StateNotifier<VocabularyState> {
  final Ref ref;

  VocabularyController(this.ref) : super(const VocabularyState.initial());

  Future<void> loadVocabulary({String? lessonId}) async {
    state = state.copyWith(
      status: ContentStatus.loading,
      lessonId: lessonId,
      clearLessonId: lessonId == null,
      clearMessage: true,
    );
    await _load();
  }

  Future<void> searchVocabulary(String query) async {
    state = state.copyWith(query: query, clearMessage: true);
    await _load();
  }

  Future<void> filterByTag(String tag) async {
    state = state.copyWith(tag: tag, clearMessage: true);
    await _load();
  }

  Future<void> retry() async {
    state = state.copyWith(status: ContentStatus.loading, clearMessage: true);
    await _load();
  }

  Future<void> _load() async {
    try {
      final repository = await ref.read(vocabularyRepositoryProvider.future);
      final result = await _read(repository);
      state = state.copyWith(
        status: result.hasError
            ? ContentStatus.error
            : result.isOffline
                ? ContentStatus.offline
                : ContentStatus.data,
        vocabulary: result.data,
        message: result.errorMessage,
      );
    } catch (error) {
      state = state.copyWith(
        status: ContentStatus.error,
        message: ApiClient.describeError(error),
      );
    }
  }

  Future<ContentResult<List<Vocabulary>>> _read(
    VocabularyRepository repository,
  ) {
    final query = state.query.trim();
    final tag = state.tag == 'All' ? '' : state.tag;
    final lessonId = state.lessonId;

    if (lessonId != null && lessonId.isNotEmpty) {
      return repository.getByLessonId(lessonId).then(
            (result) => ContentResult(
              data: _filterLocal(result.data),
              isOffline: result.isOffline,
              errorMessage: result.errorMessage,
            ),
          );
    }
    if (query.isNotEmpty) return repository.searchVocabulary(query);
    if (tag.isNotEmpty) return repository.filterByTag(tag);
    return repository.getVocabulary();
  }

  List<Vocabulary> _filterLocal(List<Vocabulary> vocabulary) {
    final normalizedQuery = state.query.trim().toLowerCase();
    final normalizedTag = state.tag == 'All' ? '' : state.tag.toLowerCase();
    return vocabulary.where((item) {
      final matchesQuery = normalizedQuery.isEmpty ||
          item.word.toLowerCase().contains(normalizedQuery) ||
          item.hiragana.toLowerCase().contains(normalizedQuery) ||
          item.romaji.toLowerCase().contains(normalizedQuery) ||
          item.meaningVi.toLowerCase().contains(normalizedQuery);
      final matchesTag = normalizedTag.isEmpty ||
          item.tags.any((tag) => tag.toLowerCase() == normalizedTag);
      return matchesQuery && matchesTag;
    }).toList();
  }
}
