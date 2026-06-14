import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../models/writing_models.dart';
import '../repositories/writing_repository.dart';

class WritingHistoryScreen extends StatefulWidget {
  final String? lessonId;
  final String? lessonTitle;

  const WritingHistoryScreen({
    super.key,
    this.lessonId,
    this.lessonTitle,
  });

  @override
  State<WritingHistoryScreen> createState() => _WritingHistoryScreenState();
}

class _WritingHistoryScreenState extends State<WritingHistoryScreen> {
  final _repository = WritingRepository();
  late Future<List<WritingSubmission>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getSubmissions(lessonId: widget.lessonId);
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.lessonTitle?.isNotEmpty == true
        ? widget.lessonTitle!
        : context.tr('All writing practice');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: context.colors.ink,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('Writing History')),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.captionText,
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<WritingSubmission>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _message(ApiClient.describeError(snapshot.error!));
          }
          final submissions = snapshot.data ?? const [];
          if (submissions.isEmpty) {
            return _message(context.tr('No writing submissions yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            itemCount: submissions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _submissionCard(submissions[index]),
          );
        },
      ),
    );
  }

  Widget _submissionCard(WritingSubmission submission) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _statusLabel(submission),
                  style: AppTextStyles.overline.copyWith(
                    color: submission.pendingSync
                        ? AppColors.gold
                        : AppColors.primary,
                  ),
                ),
              ),
              Text(
                '${submission.score}',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            submission.answerText,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: context.bodyText,
          ),
          if (submission.feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(submission.feedback, style: context.captionText),
          ],
        ],
      ),
    );
  }

  Widget _message(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.bodyText.copyWith(color: context.colors.mute),
        ),
      ),
    );
  }

  String _statusLabel(WritingSubmission submission) {
    if (submission.pendingSync) return context.tr('PENDING SYNC');
    return submission.status.toUpperCase();
  }
}
