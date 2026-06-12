import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/media/audio_cache_service.dart';
import '../core/media/audio_player_service.dart';
import '../core/network/api_client.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

class FlashcardDimensions {
  static const double desktopWidth = 420;
  static const double desktopHeight = 620;
  static const double maxPhoneWidth = 420;
  static const double maxTabletWidth = 480;
  static const double responsiveHeightRatio = 1.45;

  static Size resolve(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final platform = Theme.of(context).platform;
    final isDesktop = platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;

    if (isDesktop) {
      return const Size(desktopWidth, desktopHeight);
    }

    final isTablet = size.shortestSide >= 600;
    final width = isTablet
        ? math.min(size.width * 0.5, maxTabletWidth)
        : math.min(size.width * 0.75, maxPhoneWidth);

    return Size(width, width * responsiveHeightRatio);
  }
}

class FlipFlashcard extends StatefulWidget {
  final String kanji;
  final String kana;
  final String romaji;
  final String meaning;
  final String example;
  final String exampleTr;
  final String audioUrl;
  final int resetToken;
  const FlipFlashcard({
    super.key,
    required this.kanji,
    required this.kana,
    required this.romaji,
    required this.meaning,
    required this.example,
    required this.exampleTr,
    this.audioUrl = '',
    this.resetToken = 0,
  });

  @override
  State<FlipFlashcard> createState() => _FlipFlashcardState();
}

class _FlipFlashcardState extends State<FlipFlashcard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
  late final AudioPlayerService _audioPlayerService = AudioPlayerService();
  late final AudioCacheService _audioCacheService = AudioCacheService();

  @override
  void didUpdateWidget(covariant FlipFlashcard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _audioPlayerService.dispose();
    super.dispose();
  }

  void _flip() => _c.isCompleted ? _c.reverse() : _c.forward();

  Future<void> _playAudio() async {
    final url = widget.audioUrl.trim();
    if (url.isEmpty) {
      _showAudioMessage('Audio is not available yet.');
      return;
    }

    try {
      final cachedPath = await _audioCacheService.cachedPathForUrl(url);
      if (cachedPath != null) {
        await _audioPlayerService.playLocalFile(cachedPath);
        return;
      }
      await _audioPlayerService.playUrl(url);
      await _audioCacheService.cacheRemoteAudio(url);
    } catch (error) {
      _showAudioMessage(ApiClient.describeError(error));
    }
  }

  void _showAudioMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = FlashcardDimensions.resolve(context);

    return SizedBox(
      width: dimensions.width,
      height: dimensions.height,
      child: GestureDetector(
        onTap: _flip,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final angle = _c.value * math.pi;
            final showBack = _c.value > 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _back(),
                    )
                  : _front(),
            );
          },
        ),
      ),
    );
  }

  Widget _front() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppShadows.elevated,
        ),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text('TAP TO FLIP',
                style: AppTextStyles.overline.copyWith(color: Colors.white70)),
            const SizedBox(height: 16),
            Expanded(
              flex: 6,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.kanji,
                    style: AppTextStyles.jp(
                      110,
                      color: Colors.white,
                      w: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.kana,
                    style: AppTextStyles.jp(
                      22,
                      color: Colors.white70,
                      w: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: IconButton(
                tooltip: 'Play audio',
                onPressed: _playAudio,
                icon: const Icon(Icons.volume_up_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      );

  Widget _back() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppShadows.elevated,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('MEANING', style: AppTextStyles.overline),
                    const SizedBox(height: 12),
                    Text(
                      widget.meaning,
                      style: AppTextStyles.h1.copyWith(fontSize: 30),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.romaji,
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.example,
                            style: AppTextStyles.jp(16, w: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(widget.exampleTr, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}
