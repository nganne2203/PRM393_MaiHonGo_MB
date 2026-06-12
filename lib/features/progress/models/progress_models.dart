class ProgressModel {
  final String id;
  final String lessonId;
  final int lastViewedVocabIndex;
  final bool completed;
  final int score;
  final String practiceType;
  final int completedWritingCount;
  final DateTime? lastPracticeAt;

  const ProgressModel({
    required this.id,
    required this.lessonId,
    required this.lastViewedVocabIndex,
    required this.completed,
    required this.score,
    required this.practiceType,
    required this.completedWritingCount,
    this.lastPracticeAt,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) => ProgressModel(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        lessonId: json['lessonId']?.toString() ?? '',
        lastViewedVocabIndex: _toInt(json['lastViewedVocabIndex']),
        completed: json['completed'] == true,
        score: _toInt(json['score']),
        practiceType: json['practiceType']?.toString() ?? 'vocabulary',
        completedWritingCount: _toInt(json['completedWritingCount']),
        lastPracticeAt:
            DateTime.tryParse(json['lastPracticeAt']?.toString() ?? ''),
      );
}

class ProgressUpdateRequest {
  final String lessonId;
  final int lastViewedVocabIndex;
  final bool completed;
  final int score;
  final String practiceType;
  final int? completedWritingCount;
  final int? totalPracticeScore;
  final DateTime clientUpdatedAt;

  const ProgressUpdateRequest({
    required this.lessonId,
    required this.lastViewedVocabIndex,
    required this.completed,
    required this.score,
    required this.practiceType,
    this.completedWritingCount,
    this.totalPracticeScore,
    required this.clientUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'lastViewedVocabIndex': lastViewedVocabIndex,
        'completed': completed,
        'score': score,
        'practiceType': practiceType,
        if (completedWritingCount != null)
          'completedWritingCount': completedWritingCount,
        if (totalPracticeScore != null)
          'totalPracticeScore': totalPracticeScore,
        'lastPracticeAt': clientUpdatedAt.toIso8601String(),
        'clientUpdatedAt': clientUpdatedAt.toIso8601String(),
      };

  factory ProgressUpdateRequest.fromJson(Map<String, dynamic> json) {
    return ProgressUpdateRequest(
      lessonId: json['lessonId']?.toString() ?? '',
      lastViewedVocabIndex: _toInt(json['lastViewedVocabIndex']),
      completed: json['completed'] == true,
      score: _toInt(json['score']),
      practiceType: json['practiceType']?.toString() ?? 'vocabulary',
      completedWritingCount: json.containsKey('completedWritingCount')
          ? _toInt(json['completedWritingCount'])
          : null,
      totalPracticeScore: json.containsKey('totalPracticeScore')
          ? _toInt(json['totalPracticeScore'])
          : null,
      clientUpdatedAt:
          DateTime.tryParse(json['clientUpdatedAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
