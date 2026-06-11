import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/state/auth_state.dart';
import '../models/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

enum DashboardStatus {
  initial,
  loading,
  data,
  error,
  refreshing,
}

class DashboardState {
  final DashboardStatus status;
  final DashboardSummary? summary;
  final String? message;

  const DashboardState({
    required this.status,
    this.summary,
    this.message,
  });

  const DashboardState.initial() : this(status: DashboardStatus.initial);

  bool get hasData => summary != null;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardSummary? summary,
    String? message,
    bool clearMessage = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(apiClient: ref.watch(apiClientProvider));
});

final dashboardProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final controller =
      DashboardController(ref.watch(dashboardRepositoryProvider));
  controller.load();
  return controller;
});

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository repository;

  DashboardController(this.repository) : super(const DashboardState.initial());

  Future<void> load({bool refresh = false}) async {
    state = state.copyWith(
      status: refresh && state.hasData
          ? DashboardStatus.refreshing
          : DashboardStatus.loading,
      clearMessage: true,
    );

    try {
      final summary = await repository.getDashboardSummary();
      state = DashboardState(status: DashboardStatus.data, summary: summary);
    } catch (error) {
      state = state.copyWith(
        status: DashboardStatus.error,
        message: ApiClient.describeError(error),
      );
    }
  }
}
