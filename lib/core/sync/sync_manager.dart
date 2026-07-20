import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/state/auth_state.dart';
import '../../features/bookmarks/models/bookmark.dart';
import '../../features/bookmarks/repositories/bookmark_repository.dart';
import '../../features/flashcards/repositories/flashcard_session_repository.dart';
import '../../features/listening/repositories/listening_repository.dart';
import '../../features/progress/repositories/progress_repository.dart';
import '../../features/quiz/repositories/quiz_repository.dart';
import '../../features/speaking/repositories/speaking_repository.dart';
import '../../features/writing/repositories/writing_repository.dart';
import '../network/api_client.dart';
import '../storage/local_database_provider.dart';
import '../storage/local_database_service.dart';

class SyncReport {
  final DateTime completedAt;
  final int syncedItems;
  final List<String> failedGroups;

  const SyncReport({
    required this.completedAt,
    required this.syncedItems,
    required this.failedGroups,
  });

  bool get succeeded => failedGroups.isEmpty;
}

class SyncManager extends ChangeNotifier {
  final BookmarkRepository bookmarkRepository;
  final FlashcardSessionRepository flashcardRepository;
  final ProgressRepository progressRepository;
  final QuizRepository quizRepository;
  final ListeningRepository listeningRepository;
  final SpeakingRepository speakingRepository;
  final WritingRepository writingRepository;
  final Connectivity connectivity;
  final ApiClient apiClient;
  final LocalDatabaseService localDatabase;

  bool _isSyncing = false;
  SyncReport? _lastReport;

  SyncManager({
    required this.bookmarkRepository,
    required this.flashcardRepository,
    required this.progressRepository,
    required this.quizRepository,
    required this.listeningRepository,
    required this.speakingRepository,
    required this.writingRepository,
    required this.apiClient,
    required this.localDatabase,
    Connectivity? connectivity,
  }) : connectivity = connectivity ?? Connectivity();

  bool get isSyncing => _isSyncing;
  SyncReport? get lastReport => _lastReport;

  Future<SyncReport> synchronize() async {
    if (_isSyncing) {
      return _lastReport ??
          SyncReport(
            completedAt: DateTime.now(),
            syncedItems: 0,
            failedGroups: const [],
          );
    }
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return SyncReport(
        completedAt: DateTime.now(),
        syncedItems: 0,
        failedGroups: const ['network'],
      );
    }

    _isSyncing = true;
    notifyListeners();
    var syncedItems = 0;
    final failures = <String>[];

    Future<void> run(String group, Future<int> Function() action) async {
      try {
        syncedItems += await action();
      } catch (_) {
        failures.add(group);
      }
    }

    await run('bookmarks', bookmarkRepository.syncPendingOperations);
    await run('flashcards', flashcardRepository.syncPendingResults);
    await run('progress',
        () async => (await progressRepository.syncPendingProgress()).length);
    await run(
        'quiz', () async => (await quizRepository.syncPendingResults()).length);
    await run('listening',
        () async => (await listeningRepository.syncPendingAttempts()).length);
    await run('speaking',
        () async => (await speakingRepository.syncPendingAttempts()).length);
    await run('writing',
        () async => (await writingRepository.syncPendingSubmissions()).length);
    await run('pull', _pullLatestState);

    _lastReport = SyncReport(
      completedAt: DateTime.now(),
      syncedItems: syncedItems,
      failedGroups: failures,
    );
    _isSyncing = false;
    notifyListeners();
    return _lastReport!;
  }

  Future<int> _pullLatestState() async {
    final response = await apiClient.dio.get('/sync/pull');
    final data = ApiEnvelope.unwrapData(asJsonMap(response.data));
    if (data is! Map) return 0;
    final bookmarks = data['bookmarks'];
    if (bookmarks is List) {
      await localDatabase.saveBookmarks(
        bookmarks
            .whereType<Map>()
            .map((item) => Bookmark.fromJson(asJsonMap(item)))
            .toList(),
      );
    }
    return 0;
  }
}

final syncManagerProvider = FutureProvider<SyncManager>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final database = await ref.watch(localDatabaseProvider.future);
  final databaseFuture = Future.value(database);
  return SyncManager(
    bookmarkRepository: BookmarkRepository(
      apiClient: apiClient,
      localDatabase: databaseFuture,
    ),
    flashcardRepository: FlashcardSessionRepository(
      apiClient: apiClient,
      localDatabase: database,
    ),
    progressRepository: ProgressRepository(apiClient: apiClient),
    quizRepository: QuizRepository(apiClient: apiClient),
    listeningRepository: ListeningRepository(
      apiClient: apiClient,
      localDatabase: databaseFuture,
    ),
    speakingRepository: SpeakingRepository(
      apiClient: apiClient,
      localDatabase: databaseFuture,
    ),
    writingRepository: WritingRepository(
      apiClient: apiClient,
      localDatabase: databaseFuture,
    ),
    apiClient: apiClient,
    localDatabase: database,
  );
});

class SyncLifecycle extends ConsumerStatefulWidget {
  final Widget child;

  const SyncLifecycle({super.key, required this.child});

  @override
  ConsumerState<SyncLifecycle> createState() => _SyncLifecycleState();
}

class _SyncLifecycleState extends ConsumerState<SyncLifecycle>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_sync);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        if (!results.contains(ConnectivityResult.none)) _sync();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  Future<void> _sync() async {
    try {
      final manager = await ref.read(syncManagerProvider.future);
      await manager.synchronize();
    } catch (_) {
      // Sync is retried on the next lifecycle or connectivity event.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
