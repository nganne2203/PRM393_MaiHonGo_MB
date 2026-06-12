import '../../../core/network/api_client.dart';

class VocabularyExample {
  final String jp;
  final String vi;

  const VocabularyExample({
    required this.jp,
    required this.vi,
  });

  factory VocabularyExample.fromJson(Map<String, dynamic> json) {
    return VocabularyExample(
      jp: json['jp']?.toString() ?? '',
      vi: json['vi']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'jp': jp,
        'vi': vi,
      };
}

class Vocabulary {
  final String id;
  final String word;
  final String hiragana;
  final String romaji;
  final String meaningVi;
  final List<VocabularyExample> examples;
  final List<String> tags;
  final String? lessonId;
  final String audioUrl;
  final String? audioAssetId;
  final DateTime? updatedAt;

  const Vocabulary({
    required this.id,
    required this.word,
    required this.hiragana,
    required this.romaji,
    required this.meaningVi,
    required this.examples,
    required this.tags,
    this.lessonId,
    this.audioUrl = '',
    this.audioAssetId,
    this.updatedAt,
  });

  factory Vocabulary.fromJson(
    Map<String, dynamic> json, {
    String? lessonId,
  }) {
    final examples = json['examples'];
    final tags = json['tags'];
    return Vocabulary(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      word: (json['word'] ?? json['kanji'] ?? '').toString(),
      hiragana: (json['hiragana'] ?? json['kana'] ?? '').toString(),
      romaji: json['romaji']?.toString() ?? '',
      meaningVi: (json['meaningVi'] ?? json['meaning'] ?? '').toString(),
      examples: examples is List
          ? examples
              .whereType<Map>()
              .map((item) => VocabularyExample.fromJson(asJsonMap(item)))
              .toList()
          : const [],
      tags:
          tags is List ? tags.map((tag) => tag.toString()).toList() : const [],
      lessonId: lessonId ?? json['lessonId']?.toString(),
      audioUrl: json['audioUrl']?.toString() ?? '',
      audioAssetId: json['audioAssetId']?.toString(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Vocabulary copyWith({
    String? lessonId,
  }) {
    return Vocabulary(
      id: id,
      word: word,
      hiragana: hiragana,
      romaji: romaji,
      meaningVi: meaningVi,
      examples: examples,
      tags: tags,
      lessonId: lessonId ?? this.lessonId,
      audioUrl: audioUrl,
      audioAssetId: audioAssetId,
      updatedAt: updatedAt,
    );
  }
}
