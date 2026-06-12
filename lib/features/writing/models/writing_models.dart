class WritingPrompt {
  final String id;
  final String lessonId;
  final String lessonTitle;
  final String promptText;
  final String promptType;
  final String expectedAnswer;
  final String sampleAnswer;
  final String rubric;
  final String difficulty;

  const WritingPrompt({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.promptText,
    required this.promptType,
    required this.expectedAnswer,
    required this.sampleAnswer,
    required this.rubric,
    required this.difficulty,
  });

  factory WritingPrompt.fromJson(Map<String, dynamic> json) {
    final lesson = json['lessonId'];
    String lessonId = '';
    String lessonTitle = json['lessonTitle']?.toString() ?? '';
    if (lesson is Map) {
      lessonId = (lesson['_id'] ?? lesson['id'] ?? '').toString();
      lessonTitle =
          lessonTitle.isEmpty ? lesson['title']?.toString() ?? '' : lessonTitle;
    } else {
      lessonId = lesson?.toString() ?? '';
    }

    return WritingPrompt(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      promptText: json['promptText']?.toString() ?? '',
      promptType: json['promptType']?.toString() ?? 'sentence',
      expectedAnswer: json['expectedAnswer']?.toString() ?? '',
      sampleAnswer: json['sampleAnswer']?.toString() ?? '',
      rubric: json['rubric']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'beginner',
    );
  }
}

class WritingSubmissionRequest {
  final String promptId;
  final String lessonId;
  final String answerText;
  final DateTime submittedAt;
  final String syncSource;
  final String clientSubmissionId;

  const WritingSubmissionRequest({
    required this.promptId,
    required this.lessonId,
    required this.answerText,
    required this.submittedAt,
    required this.syncSource,
    required this.clientSubmissionId,
  });

  Map<String, dynamic> toJson() => {
        'promptId': promptId,
        'lessonId': lessonId,
        'answerText': answerText,
        'submittedAt': submittedAt.toIso8601String(),
        'syncSource': syncSource,
        'clientSubmissionId': clientSubmissionId,
      };

  factory WritingSubmissionRequest.fromJson(Map<String, dynamic> json) {
    return WritingSubmissionRequest(
      promptId: json['promptId']?.toString() ?? '',
      lessonId: json['lessonId']?.toString() ?? '',
      answerText: json['answerText']?.toString() ?? '',
      submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? '') ??
          DateTime.now(),
      syncSource: json['syncSource']?.toString() ?? 'offline',
      clientSubmissionId: json['clientSubmissionId']?.toString() ?? '',
    );
  }
}

class WritingSubmission {
  final String id;
  final String promptId;
  final String lessonId;
  final String answerText;
  final int score;
  final List<String> corrections;
  final String feedback;
  final String status;
  final DateTime? submittedAt;
  final bool pendingSync;

  const WritingSubmission({
    required this.id,
    required this.promptId,
    required this.lessonId,
    required this.answerText,
    required this.score,
    required this.corrections,
    required this.feedback,
    required this.status,
    required this.submittedAt,
    this.pendingSync = false,
  });

  factory WritingSubmission.fromJson(Map<String, dynamic> json) {
    final corrections = json['corrections'];
    return WritingSubmission(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      promptId: json['promptId']?.toString() ?? '',
      lessonId: json['lessonId']?.toString() ?? '',
      answerText: json['answerText']?.toString() ?? '',
      score: _toInt(json['score']),
      corrections: corrections is List
          ? corrections.map((item) => item.toString()).toList()
          : const [],
      feedback: json['feedback']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? ''),
    );
  }

  factory WritingSubmission.pending(WritingSubmissionRequest request) {
    return WritingSubmission(
      id: request.clientSubmissionId,
      promptId: request.promptId,
      lessonId: request.lessonId,
      answerText: request.answerText,
      score: 0,
      corrections: const [],
      feedback: 'Saved offline. This answer will sync when you reconnect.',
      status: 'pending',
      submittedAt: request.submittedAt,
      pendingSync: true,
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
