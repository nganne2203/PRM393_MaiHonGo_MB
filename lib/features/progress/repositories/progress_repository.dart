import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../models/progress_models.dart';

class ProgressRepository {
  static const _pendingKey = 'progress_pending_updates';

  final ApiClient apiClient;
  final Connectivity connectivity;

  ProgressRepository({ApiClient? apiClient, Connectivity? connectivity})
      : apiClient = apiClient ?? ApiClient(),
        connectivity = connectivity ?? Connectivity();

  Future<List<ProgressModel>> getProgress() async {
    final response = await apiClient.dio.get('/progress');
    final data = ApiEnvelope.unwrapData(asJsonMap(response.data));
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => ProgressModel.fromJson(asJsonMap(item)))
        .toList();
  }

  Future<ProgressModel?> getLessonProgress(String lessonId) async {
    final response = await apiClient.dio.get('/progress/$lessonId');
    final data = ApiEnvelope.unwrapData(asJsonMap(response.data));
    if (data == null) return null;
    if (data is! Map) throw const ApiException('Progress response is invalid.');
    return ProgressModel.fromJson(asJsonMap(data));
  }

  Future<ProgressModel> updateProgress(ProgressUpdateRequest request) async {
    if (!await isOnline()) {
      await _savePending(request);
      return _localProgress(request);
    }

    final response =
        await apiClient.dio.put('/progress', data: request.toJson());
    final data = ApiEnvelope.unwrapData(asJsonMap(response.data));
    if (data is! Map) throw const ApiException('Progress response is invalid.');
    return ProgressModel.fromJson(asJsonMap(data));
  }

  Future<List<ProgressModel>> syncPendingProgress() async {
    if (!await isOnline()) return [];
    final pending = await _loadPending();
    final synced = <ProgressModel>[];

    for (final request in pending) {
      try {
        final response =
            await apiClient.dio.put('/progress', data: request.toJson());
        final data = ApiEnvelope.unwrapData(asJsonMap(response.data));
        if (data is Map) {
          synced.add(ProgressModel.fromJson(asJsonMap(data)));
        }
      } catch (_) {
        await _saveAllPending(pending);
        return synced;
      }
    }

    await _saveAllPending([]);
    return synced;
  }

  Future<bool> isOnline() async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> _savePending(ProgressUpdateRequest request) async {
    final pending = await _loadPending();
    final filtered = pending
        .where((item) =>
            item.lessonId != request.lessonId ||
            item.practiceType != request.practiceType)
        .toList();
    filtered.add(request);
    await _saveAllPending(filtered);
  }

  Future<List<ProgressUpdateRequest>> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => ProgressUpdateRequest.fromJson(asJsonMap(item)))
        .where((item) => item.lessonId.isNotEmpty)
        .toList();
  }

  Future<void> _saveAllPending(List<ProgressUpdateRequest> updates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingKey,
      jsonEncode(updates.map((item) => item.toJson()).toList()),
    );
  }

  ProgressModel _localProgress(ProgressUpdateRequest request) {
    return ProgressModel(
      id: 'pending-${request.lessonId}-${request.practiceType}',
      lessonId: request.lessonId,
      lastViewedVocabIndex: request.lastViewedVocabIndex,
      completed: request.completed,
      score: request.score,
      practiceType: request.practiceType,
      completedWritingCount: request.completedWritingCount ?? 0,
      lastPracticeAt: request.clientUpdatedAt,
    );
  }
}
