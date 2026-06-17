import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/tokens.dart';
import '../models/speaking_models.dart';
import '../repositories/speaking_repository.dart';

class SpeakingHistoryScreen extends StatefulWidget {
  const SpeakingHistoryScreen({super.key});

  @override
  State<SpeakingHistoryScreen> createState() => _SpeakingHistoryScreenState();
}

class _SpeakingHistoryScreenState extends State<SpeakingHistoryScreen> {
  final _repository = SpeakingRepository();
  final _player = AudioPlayer();
  late Future<List<SpeakingAttempt>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getAttempts();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(context.tr('Speaking History')),
      ),
      body: SafeArea(
        child: FutureBuilder<List<SpeakingAttempt>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _CenteredMessage(
                  message: ApiClient.describeError(snapshot.error!));
            }
            final attempts = snapshot.data ?? const [];
            if (attempts.isEmpty) {
              return const _CenteredMessage(
                  message: 'No speaking attempts yet.');
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              itemBuilder: (_, index) => _AttemptCard(
                attempt: attempts[index],
                onPlay: () => _play(attempts[index]),
              ),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: attempts.length,
            );
          },
        ),
      ),
    );
  }

  Future<void> _play(SpeakingAttempt attempt) async {
    final localPath = attempt.localAudioPath;
    if (localPath != null && localPath.isNotEmpty) {
      await _player.setFilePath(localPath);
    } else if (attempt.recordingUrl.startsWith('/')) {
      await _player
          .setUrl('${ApiClient.defaultBaseUrl}${attempt.recordingUrl}');
    } else {
      await _player.setUrl(attempt.recordingUrl);
    }
    await _player.play();
  }
}

class _AttemptCard extends StatelessWidget {
  final SpeakingAttempt attempt;
  final VoidCallback onPlay;

  const _AttemptCard({
    required this.attempt,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = attempt.status == 'pendingSync';
    final scoreColor = isPending ? AppColors.gold : AppColors.primary;
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
            backgroundColor: scoreColor.withValues(alpha: 0.14),
            child: Text(
              isPending ? '...' : '${attempt.similarityScore}',
              style: TextStyle(color: scoreColor, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.promptText.isEmpty
                      ? attempt.expectedText
                      : attempt.promptText,
                  style: context.h3,
                ),
                const SizedBox(height: 4),
                Text(
                  attempt.feedback,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.captionText,
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(_statusText(attempt.status)),
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr('Replay recording'),
            icon: const Icon(Icons.play_circle_fill_rounded),
            onPressed:
                attempt.recordingUrl.isEmpty && attempt.localAudioPath == null
                    ? null
                    : onPlay,
          ),
        ],
      ),
    );
  }

  String _statusText(String status) {
    if (status == 'pendingSync') return 'Pending sync';
    return status;
  }
}

class _CenteredMessage extends StatelessWidget {
  final String message;

  const _CenteredMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(context.tr(message),
            textAlign: TextAlign.center, style: context.bodyText),
      ),
    );
  }
}
