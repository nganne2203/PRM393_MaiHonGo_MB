class LocalContentPackage {
  final String lessonId;
  final int version;
  final int size;
  final DateTime downloadedAt;
  final String? status;

  const LocalContentPackage({
    required this.lessonId,
    required this.version,
    required this.size,
    required this.downloadedAt,
    this.status,
  });
}

class LocalFlashcardSessionResult {
  final String? lessonId;
  final int totalCards;
  final int learnedCount;
  final int notLearnedCount;
  final int accuracy;
  final List<String> learnedVocabularyIds;
  final List<String> notLearnedVocabularyIds;
  final DateTime completedAt;
  final bool synced;

  const LocalFlashcardSessionResult({
    required this.lessonId,
    required this.totalCards,
    required this.learnedCount,
    required this.notLearnedCount,
    required this.accuracy,
    required this.learnedVocabularyIds,
    required this.notLearnedVocabularyIds,
    required this.completedAt,
    required this.synced,
  });
}
