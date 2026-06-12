class SpeakingPrompt {
  final String id;
  final String lessonId;
  final String lessonTitle;
  final String? vocabId;
  final String promptText;
  final String expectedText;
  final String expectedReading;
  final String sampleAudioUrl;
  final String difficulty;

  const SpeakingPrompt({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    this.vocabId,
    required this.promptText,
    required this.expectedText,
    required this.expectedReading,
    required this.sampleAudioUrl,
    required this.difficulty,
  });

  factory SpeakingPrompt.fromJson(Map<String, dynamic> json) {
    final lesson = json['lessonId'];
    final lessonJson = lesson is Map ? lesson : null;
    return SpeakingPrompt(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      lessonId:
          lessonJson?['_id']?.toString() ?? json['lessonId']?.toString() ?? '',
      lessonTitle: json['lessonTitle']?.toString() ??
          lessonJson?['title']?.toString() ??
          '',
      vocabId: json['vocabId']?.toString(),
      promptText: json['promptText']?.toString() ?? '',
      expectedText: json['expectedText']?.toString() ?? '',
      expectedReading: json['expectedReading']?.toString() ?? '',
      sampleAudioUrl: json['sampleAudioUrl']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'beginner',
    );
  }
}

class SpeakingAttempt {
  final String id;
  final String promptId;
  final String lessonId;
  final String promptText;
  final String recordingUrl;
  final String? localAudioPath;
  final String transcript;
  final String expectedText;
  final int similarityScore;
  final int pronunciationScore;
  final String feedback;
  final List<String> correctWords;
  final List<String> wrongWords;
  final String status;
  final String clientAttemptId;
  final DateTime? attemptedAt;

  const SpeakingAttempt({
    required this.id,
    required this.promptId,
    required this.lessonId,
    required this.promptText,
    required this.recordingUrl,
    this.localAudioPath,
    required this.transcript,
    required this.expectedText,
    required this.similarityScore,
    required this.pronunciationScore,
    required this.feedback,
    required this.correctWords,
    required this.wrongWords,
    required this.status,
    required this.clientAttemptId,
    required this.attemptedAt,
  });

  factory SpeakingAttempt.fromJson(Map<String, dynamic> json) {
    final prompt = json['promptId'];
    final promptJson = prompt is Map<String, dynamic> ? prompt : null;
    return SpeakingAttempt(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      promptId: promptJson?['_id']?.toString() ?? prompt?.toString() ?? '',
      lessonId: json['lessonId']?.toString() ?? '',
      promptText: promptJson?['promptText']?.toString() ?? '',
      recordingUrl: json['recordingUrl']?.toString() ?? '',
      localAudioPath: json['localAudioPath']?.toString(),
      transcript: json['transcript']?.toString() ?? '',
      expectedText: json['expectedText']?.toString() ?? '',
      similarityScore: _toInt(json['similarityScore'] ?? json['score']),
      pronunciationScore: _toInt(json['pronunciationScore'] ?? json['score']),
      feedback: json['feedback']?.toString() ?? '',
      correctWords: _toStringList(json['correctWords']),
      wrongWords: _toStringList(json['wrongWords']),
      status: json['status']?.toString() ?? 'pending',
      clientAttemptId: json['clientAttemptId']?.toString() ?? '',
      attemptedAt: DateTime.tryParse(json['attemptedAt']?.toString() ?? ''),
    );
  }

  factory SpeakingAttempt.pendingSync(PendingSpeakingAttempt pending) =>
      SpeakingAttempt(
        id: pending.clientAttemptId,
        promptId: pending.promptId,
        lessonId: pending.lessonId,
        promptText: '',
        recordingUrl: '',
        localAudioPath: pending.audioPath,
        transcript: '',
        expectedText: '',
        similarityScore: 0,
        pronunciationScore: 0,
        feedback:
            'Your speaking attempt will be evaluated when you are online.',
        correctWords: const [],
        wrongWords: const [],
        status: 'pendingSync',
        clientAttemptId: pending.clientAttemptId,
        attemptedAt: pending.createdAt,
      );
}

class PendingSpeakingAttempt {
  final String promptId;
  final String lessonId;
  final String audioPath;
  final String clientAttemptId;
  final String syncSource;
  final DateTime createdAt;

  const PendingSpeakingAttempt({
    required this.promptId,
    required this.lessonId,
    required this.audioPath,
    required this.clientAttemptId,
    required this.syncSource,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'promptId': promptId,
        'lessonId': lessonId,
        'audioPath': audioPath,
        'clientAttemptId': clientAttemptId,
        'syncSource': syncSource,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingSpeakingAttempt.fromJson(Map<String, dynamic> json) =>
      PendingSpeakingAttempt(
        promptId: json['promptId']?.toString() ?? '',
        lessonId: json['lessonId']?.toString() ?? '',
        audioPath: json['audioPath']?.toString() ?? '',
        clientAttemptId: json['clientAttemptId']?.toString() ?? '',
        syncSource: json['syncSource']?.toString() ?? 'offline',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}
