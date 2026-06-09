import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../data/vocab_data.dart';
import '../widgets/primary_button.dart';

class VocabScreen extends StatefulWidget {
  final VoidCallback onStart;
  const VocabScreen({super.key, required this.onStart});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  String _filter = 'All';
  final Set<int> _saved = {0, 4};

  @override
  Widget build(BuildContext context) {
    final list =
        kVocab.where((v) => _filter == 'All' || v.level == _filter).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const BackButton(),
            Text('Vocabulary', style: AppTextStyles.h2),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search words...',
                  hintStyle: AppTextStyles.caption,
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.mute, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.lg)),
              child:
                  const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
            ),
          ]),
          const SizedBox(height: 12),
          Row(
            children: ['All', 'N5', 'N4'].map((f) {
              final on = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: on ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: on ? AppColors.primary : AppColors.line),
                    ),
                    child: Text(f,
                        style: TextStyle(
                          color: on ? Colors.white : AppColors.mute,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, idx) {
                final v = list[idx];
                final saved = _saved.contains(idx);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                      alignment: Alignment.center,
                      child: Text(v.kanji,
                          style:
                              AppTextStyles.jp(24, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(v.kana,
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: v.level == 'N5'
                                  ? AppColors.sakuraSoft
                                  : AppColors.skySoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(v.level,
                                style: TextStyle(
                                  color: v.level == 'N5'
                                      ? AppColors.sakura
                                      : AppColors.sky,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                        ]),
                        Text('${v.romaji} · ${v.meaning}',
                            style: AppTextStyles.caption),
                      ],
                    )),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded,
                          color: AppColors.primary, size: 18),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: saved ? AppColors.sakura : AppColors.mute,
                          size: 18),
                      onPressed: () => setState(
                          () => saved ? _saved.remove(idx) : _saved.add(idx)),
                    ),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
              label: 'Start Flashcard Session →', onTap: widget.onStart),
        ]),
      ),
    );
  }
}
