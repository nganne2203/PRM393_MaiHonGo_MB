import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/tokens.dart';
import '../models/quiz_models.dart';
import '../repositories/quiz_repository.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  final _repository = QuizRepository();
  late Future<List<QuizResult>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getQuizResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(context.tr('Quiz History'))),
      body: FutureBuilder<List<QuizResult>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _message(ApiClient.describeError(snapshot.error!));
          }
          final results = snapshot.data ?? const [];
          if (results.isEmpty) {
            return _message(context.tr('No quiz results yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) => _resultCard(results[index]),
          );
        },
      ),
    );
  }

  Widget _resultCard(QuizResult result) {
    final accuracy =
        result.total == 0 ? 0 : (result.score * 100 / result.total).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            child: Text('$accuracy%',
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${result.score} / ${result.total}', style: context.h3),
                Text(
                  result.pendingSync
                      ? context.tr('Pending sync')
                      : context.tr('Saved'),
                  style: context.captionText,
                ),
              ],
            ),
          ),
          Text('${result.durationSec}s', style: context.captionText),
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
