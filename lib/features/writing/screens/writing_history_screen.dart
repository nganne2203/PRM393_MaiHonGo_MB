import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
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
        : 'All writing practice';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Writing History'),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: AppColors.mute),
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
            return _message('No writing submissions yet.');
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
        color: Colors.white,
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
            style: AppTextStyles.body,
          ),
          if (submission.feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(submission.feedback, style: AppTextStyles.caption),
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
          style: AppTextStyles.body.copyWith(color: AppColors.mute),
        ),
      ),
    );
  }

  String _statusLabel(WritingSubmission submission) {
    if (submission.pendingSync) return 'PENDING SYNC';
    return submission.status.toUpperCase();
  }
}
