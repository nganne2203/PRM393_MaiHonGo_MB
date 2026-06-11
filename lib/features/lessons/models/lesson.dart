import '../../../core/network/api_client.dart';
import '../../vocabulary/models/vocabulary.dart';

class Lesson {
  final String id;
  final String title;
  final String category;
  final String description;
  final bool isOfflineReady;
  final bool downloadable;
  final int version;
  final int size;
  final List<String> vocabIds;
  final List<Vocabulary> vocabulary;
  final bool downloaded;
  final DateTime? updatedAt;

  const Lesson({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.isOfflineReady,
    required this.downloadable,
    required this.version,
    required this.size,
    required this.vocabIds,
    this.vocabulary = const [],
    this.downloaded = false,
    this.updatedAt,
  });

  factory Lesson.fromJson(
    Map<String, dynamic> json, {
    bool downloaded = false,
  }) {
    final rawVocabIds = json['vocabIds'];
    final vocabulary = <Vocabulary>[];
    final ids = <String>[];

    if (rawVocabIds is List) {
      for (final item in rawVocabIds) {
        if (item is Map) {
          final vocab = Vocabulary.fromJson(asJsonMap(item));
          vocabulary.add(vocab.copyWith(lessonId: json['_id']?.toString()));
          if (vocab.id.isNotEmpty) ids.add(vocab.id);
        } else if (item != null) {
          ids.add(item.toString());
        }
      }
    }

    return Lesson(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isOfflineReady: json['isOfflineReady'] == true,
      downloadable:
          json['downloadable'] == true || json['isOfflineReady'] == true,
      version: int.tryParse(json['version']?.toString() ?? '') ?? 1,
      size: int.tryParse(
            (json['size'] ?? json['assetSize'])?.toString() ?? '',
          ) ??
          0,
      vocabIds: ids,
      vocabulary: vocabulary,
      downloaded: downloaded,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Lesson copyWith({
    List<Vocabulary>? vocabulary,
    List<String>? vocabIds,
    bool? downloaded,
  }) {
    return Lesson(
      id: id,
      title: title,
      category: category,
      description: description,
      isOfflineReady: isOfflineReady,
      downloadable: downloadable,
      version: version,
      size: size,
      vocabIds: vocabIds ?? this.vocabIds,
      vocabulary: vocabulary ?? this.vocabulary,
      downloaded: downloaded ?? this.downloaded,
      updatedAt: updatedAt,
    );
  }
}
