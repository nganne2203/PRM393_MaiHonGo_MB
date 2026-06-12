import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/listening_models.dart';

class ListeningLocalStore {
  static const _pendingKey = 'listening_pending_attempts';

  Future<List<PendingListeningAttempt>> loadPendingAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => PendingListeningAttempt.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .toList();
  }

  Future<void> addPendingAttempt(PendingListeningAttempt attempt) async {
    final attempts = await loadPendingAttempts();
    final filtered = attempts
        .where((item) => item.clientAttemptId != attempt.clientAttemptId)
        .toList();
    filtered.add(attempt);
    await _save(filtered);
  }

  Future<void> removePendingAttempt(String clientAttemptId) async {
    final attempts = await loadPendingAttempts();
    await _save(
      attempts
          .where((item) => item.clientAttemptId != clientAttemptId)
          .toList(),
    );
  }

  Future<void> _save(List<PendingListeningAttempt> attempts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingKey,
      jsonEncode(attempts.map((item) => item.toJson()).toList()),
    );
  }
}
