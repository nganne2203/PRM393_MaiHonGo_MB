import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/content_state.dart';
import '../../../core/storage/local_database_provider.dart';
import '../../auth/state/auth_state.dart';
import '../models/lesson.dart';
import '../repositories/lesson_repository.dart';

class LessonState {
  final ContentStatus status;
  final List<Lesson> lessons;
  final String? message;

  const LessonState({
    required this.status,
    required this.lessons,
    this.message,
  });

  const LessonState.initial()
      : status = ContentStatus.initial,
        lessons = const [],
        message = null;

  LessonState copyWith({
    ContentStatus? status,
    List<Lesson>? lessons,
    String? message,
    bool clearMessage = false,
  }) {
    return LessonState(
      status: status ?? this.status,
      lessons: lessons ?? this.lessons,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

final lessonRepositoryProvider = FutureProvider<LessonRepository>((ref) async {
  return LessonRepository(
    apiClient: ref.watch(apiClientProvider),
    localDatabase: await ref.watch(localDatabaseProvider.future),
  );
});

final lessonProvider =
    StateNotifierProvider<LessonController, LessonState>((ref) {
  return LessonController(ref)..loadLessons();
});

class LessonController extends StateNotifier<LessonState> {
  final Ref ref;

  LessonController(this.ref) : super(const LessonState.initial());

  Future<void> loadLessons() async {
    state = state.copyWith(status: ContentStatus.loading, clearMessage: true);
    try {
      final repository = await ref.read(lessonRepositoryProvider.future);
      final cached = await repository.localDatabase.getLessons();
      if (cached.isNotEmpty) {
        state = LessonState(status: ContentStatus.offline, lessons: cached);
      }

      final result = await repository.getLessons();
      state = LessonState(
        status: result.hasError
            ? ContentStatus.error
            : result.isOffline
                ? ContentStatus.offline
                : ContentStatus.data,
        lessons: result.data,
        message: result.errorMessage,
      );
    } catch (error) {
      state = LessonState(
        status: ContentStatus.error,
        lessons: state.lessons,
        message: ApiClient.describeError(error),
      );
    }
  }
}
