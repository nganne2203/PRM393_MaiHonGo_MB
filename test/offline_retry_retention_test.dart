import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/core/network/api_client.dart';
import 'package:maihongo/features/quiz/models/quiz_models.dart';
import 'package:maihongo/features/quiz/repositories/quiz_repository.dart';
import 'package:maihongo/features/writing/models/writing_models.dart';
import 'package:maihongo/features/writing/repositories/writing_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('quiz retry retains pending data when backend is unreachable', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = QuizRepository(
      apiClient: _unreachableClient(),
      onlineCheck: () async => true,
    );
    const submission = QuizSubmission(
      lessonId: 'lesson-1',
      score: 1,
      total: 1,
      durationSec: 10,
      answers: [],
      syncSource: 'offline',
      clientAttemptId: 'quiz-pending-1',
    );

    expect((await repository.submitQuizResult(submission)).pendingSync, isTrue);
    expect(await repository.syncPendingResults(), isEmpty);
    final retained = await repository.getQuizResults();
    expect(retained.single.clientAttemptId, 'quiz-pending-1');
    expect(retained.single.pendingSync, isTrue);
  });

  test('writing retry retains pending data when backend is unreachable',
      () async {
    SharedPreferences.setMockInitialValues({});
    final database = await openTestDatabase('writing_retry_test');
    addTearDown(() => database.close(deleteFromDisk: true));
    final repository = WritingRepository(
      apiClient: _unreachableClient(),
      localDatabase: Future.value(database),
      onlineCheck: () async => true,
    );
    final request = WritingSubmissionRequest(
      promptId: 'prompt-1',
      lessonId: 'lesson-1',
      answerText: 'answer',
      submittedAt: DateTime.utc(2026, 7, 20),
      syncSource: 'offline',
      clientSubmissionId: 'writing-pending-1',
    );

    expect((await repository.submit(request)).pendingSync, isTrue);
    expect(await repository.syncPendingSubmissions(), isEmpty);
    final retained = await repository.getSubmissions();
    expect(retained.single.id, 'writing-pending-1');
    expect(retained.single.pendingSync, isTrue);
  });
}

ApiClient _unreachableClient() => fakeApiClient((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'backend unavailable',
      );
    });
