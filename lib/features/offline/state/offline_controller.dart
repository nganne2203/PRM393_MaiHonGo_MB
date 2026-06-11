import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/content_state.dart';
import '../../../core/storage/local_database_provider.dart';
import '../../auth/state/auth_state.dart';
import '../repositories/offline_repository.dart';

class OfflineState {
  final ContentStatus status;
  final List<DownloadedLesson> downloadedLessons;
  final String? message;
  final String? activeLessonId;

  const OfflineState({
    required this.status,
    required this.downloadedLessons,
    this.message,
    this.activeLessonId,
  });

  const OfflineState.initial()
      : status = ContentStatus.initial,
        downloadedLessons = const [],
        message = null,
        activeLessonId = null;

  OfflineState copyWith({
    ContentStatus? status,
    List<DownloadedLesson>? downloadedLessons,
    String? message,
    bool clearMessage = false,
    String? activeLessonId,
    bool clearActiveLessonId = false,
  }) {
    return OfflineState(
      status: status ?? this.status,
      downloadedLessons: downloadedLessons ?? this.downloadedLessons,
      message: clearMessage ? null : message ?? this.message,
      activeLessonId:
          clearActiveLessonId ? null : activeLessonId ?? this.activeLessonId,
    );
  }
}

final offlineRepositoryProvider =
    FutureProvider<OfflineRepository>((ref) async {
  return OfflineRepository.withDependencies(
    apiClient: ref.watch(apiClientProvider),
    localDatabase: await ref.watch(localDatabaseProvider.future),
  );
});

final offlineProvider =
    StateNotifierProvider<OfflineController, OfflineState>((ref) {
  return OfflineController(ref)..loadDownloadedLessons();
});

class OfflineController extends StateNotifier<OfflineState> {
  final Ref ref;

  OfflineController(this.ref) : super(const OfflineState.initial());

  Future<void> loadDownloadedLessons() async {
    state = state.copyWith(status: ContentStatus.loading, clearMessage: true);
    try {
      final repository = await ref.read(offlineRepositoryProvider.future);
      final downloaded = await repository.getDownloadedLessons();
      state = OfflineState(
        status: ContentStatus.data,
        downloadedLessons: downloaded,
      );
    } catch (error) {
      state = state.copyWith(
        status: ContentStatus.error,
        message: ApiClient.describeError(error),
      );
    }
  }

  Future<void> downloadLesson(String lessonId) async {
    state = state.copyWith(
      status: ContentStatus.loading,
      activeLessonId: lessonId,
      clearMessage: true,
    );
    try {
      final repository = await ref.read(offlineRepositoryProvider.future);
      await repository.downloadLesson(lessonId);
      final downloaded = await repository.getDownloadedLessons();
      state = OfflineState(
        status: ContentStatus.data,
        downloadedLessons: downloaded,
        message: 'Lesson downloaded for offline learning.',
      );
    } catch (error) {
      state = state.copyWith(
        status: ContentStatus.error,
        message: ApiClient.describeError(error),
        clearActiveLessonId: true,
      );
    }
  }

  Future<void> removeDownloadedLesson(String lessonId) async {
    state = state.copyWith(
      status: ContentStatus.loading,
      activeLessonId: lessonId,
      clearMessage: true,
    );
    try {
      final repository = await ref.read(offlineRepositoryProvider.future);
      await repository.removeDownloadedLesson(lessonId);
      final downloaded = await repository.getDownloadedLessons();
      state = OfflineState(
        status: ContentStatus.data,
        downloadedLessons: downloaded,
        message: 'Offline lesson removed.',
      );
    } catch (error) {
      state = state.copyWith(
        status: ContentStatus.error,
        message: ApiClient.describeError(error),
        clearActiveLessonId: true,
      );
    }
  }
}
