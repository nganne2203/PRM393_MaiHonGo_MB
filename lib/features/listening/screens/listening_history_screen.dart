import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/tokens.dart';
import '../models/listening_models.dart';
import '../repositories/listening_repository.dart';

class ListeningHistoryScreen extends StatefulWidget {
  const ListeningHistoryScreen({super.key});

  @override
  State<ListeningHistoryScreen> createState() => _ListeningHistoryScreenState();
}

class _ListeningHistoryScreenState extends State<ListeningHistoryScreen> {
  final _repository = ListeningRepository();
  late Future<List<ListeningAttempt>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getAttempts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(context.tr('Listening History'))),
      body: FutureBuilder<List<ListeningAttempt>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _message(ApiClient.describeError(snapshot.error!));
          }
          final attempts = snapshot.data ?? const [];
          if (attempts.isEmpty) {
            return _message(context.tr('No listening attempts yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            itemCount: attempts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) => _attemptCard(attempts[index]),
          );
        },
      ),
    );
  }

  Widget _attemptCard(ListeningAttempt attempt) {
    final color = attempt.pendingSync
        ? AppColors.gold
        : attempt.isCorrect
            ? AppColors.matcha
            : AppColors.sakura;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Icon(
            attempt.pendingSync
                ? Icons.sync_rounded
                : attempt.isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attempt.selectedAnswer, style: context.h3),
                Text(
                  attempt.pendingSync
                      ? context.tr('Pending sync')
                      : '${context.tr('Score')}: ${attempt.score}',
                  style: context.captionText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}
