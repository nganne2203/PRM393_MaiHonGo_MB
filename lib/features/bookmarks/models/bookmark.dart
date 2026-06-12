import '../../../core/network/api_client.dart';
import '../../vocabulary/models/vocabulary.dart';

class Bookmark {
  final String id;
  final String vocabId;
  final Vocabulary? vocabulary;
  final DateTime? createdAt;

  const Bookmark({
    required this.id,
    required this.vocabId,
    this.vocabulary,
    this.createdAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    final vocab = json['vocabId'];
    final vocabJson = vocab is Map ? asJsonMap(vocab) : null;
    return Bookmark(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      vocabId: vocabJson?['_id']?.toString() ?? vocab?.toString() ?? '',
      vocabulary: vocabJson == null ? null : Vocabulary.fromJson(vocabJson),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
