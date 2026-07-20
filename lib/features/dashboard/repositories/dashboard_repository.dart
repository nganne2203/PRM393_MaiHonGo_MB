import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../models/dashboard_summary.dart';

class DashboardRepository {
  static const _cacheKey = 'dashboard_summary_cache';
  final ApiClient apiClient;
  final Future<SharedPreferences> _preferences;

  DashboardRepository({
    required this.apiClient,
    Future<SharedPreferences>? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance();

  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final response = await apiClient.dio.get('/dashboard/summary');
      await (await _preferences).setString(
        _cacheKey,
        jsonEncode(response.data),
      );
      return DashboardSummary.fromEnvelope(response.data);
    } catch (_) {
      final cached = (await _preferences).getString(_cacheKey);
      if (cached == null || cached.isEmpty) rethrow;
      return DashboardSummary.fromEnvelope(jsonDecode(cached));
    }
  }
}
