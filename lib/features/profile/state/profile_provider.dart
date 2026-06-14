import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_database_provider.dart';
import '../../auth/state/auth_state.dart';
import '../../bookmarks/repositories/bookmark_repository.dart';
import '../../progress/repositories/progress_repository.dart';
import '../../settings/repositories/app_preferences_repository.dart';
import '../models/profile_summary.dart';
import '../repositories/profile_preferences_repository.dart';
import '../repositories/profile_repository.dart';

final profileRepositoryProvider =
    FutureProvider<ProfileRepository>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final localDatabase = await ref.watch(localDatabaseProvider.future);

  return ProfileRepository(
    authRepository: ref.watch(authRepositoryProvider),
    bookmarkRepository: BookmarkRepository(
      apiClient: apiClient,
      localDatabase: Future.value(localDatabase),
    ),
    progressRepository: ProgressRepository(apiClient: apiClient),
    localDatabase: localDatabase,
    preferencesRepository: AppPreferencesRepository(),
    profilePreferencesRepository: ProfilePreferencesRepository(),
  );
});

final profileSummaryProvider =
    FutureProvider.autoDispose<ProfileSummary>((ref) async {
  final repository = await ref.watch(profileRepositoryProvider.future);
  final authState = ref.watch(authControllerProvider);
  return repository.getProfile(authState.user);
});
