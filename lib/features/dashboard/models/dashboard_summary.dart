import '../../../core/network/api_client.dart';

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value) => value?.toString() ?? '';

Map<String, dynamic> _asOptionalJsonMap(dynamic value) {
  if (value is Map) return asJsonMap(value);
  return const {};
}

class DashboardSummary {
  final DashboardUser user;
  final DashboardStats stats;
  final ContinueLearning? continueLearning;
  final PracticeSummary practiceSummary;
  final List<RecommendedCourse> recommendedCourses;

  const DashboardSummary({
    required this.user,
    required this.stats,
    required this.continueLearning,
    required this.practiceSummary,
    required this.recommendedCourses,
  });

  factory DashboardSummary.fromEnvelope(dynamic responseData) {
    final data = ApiEnvelope.unwrapData(asJsonMap(responseData));
    if (data is! Map) {
      throw const ApiException('Backend did not return dashboard summary.');
    }
    return DashboardSummary.fromJson(asJsonMap(data));
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final courses = json['recommendedCourses'];
    final continueLearning = json['continueLearning'];

    return DashboardSummary(
      user: DashboardUser.fromJson(_asOptionalJsonMap(json['user'])),
      stats: DashboardStats.fromJson(_asOptionalJsonMap(json['stats'])),
      continueLearning: continueLearning is Map
          ? ContinueLearning.fromJson(asJsonMap(continueLearning))
          : null,
      practiceSummary: PracticeSummary.fromJson(
        _asOptionalJsonMap(json['practiceSummary']),
      ),
      recommendedCourses: courses is List
          ? courses
              .whereType<Map>()
              .map((item) => RecommendedCourse.fromJson(asJsonMap(item)))
              .where((item) => item.id.isNotEmpty || item.title.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

class DashboardUser {
  final String id;
  final String name;
  final String avatarUrl;

  const DashboardUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  factory DashboardUser.fromJson(Map<String, dynamic> json) {
    return DashboardUser(
      id: _asString(json['id']),
      name:
          _asString(json['name']).isEmpty ? 'Learner' : _asString(json['name']),
      avatarUrl: _asString(json['avatarUrl']),
    );
  }
}

class DashboardStats {
  final int streakDays;
  final int xpToday;
  final int dailyGoalCompleted;
  final int dailyGoalTarget;

  const DashboardStats({
    required this.streakDays,
    required this.xpToday,
    required this.dailyGoalCompleted,
    required this.dailyGoalTarget,
  });

  double get dailyGoalProgress {
    if (dailyGoalTarget <= 0) return 0;
    return (dailyGoalCompleted / dailyGoalTarget).clamp(0, 1).toDouble();
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      streakDays: _asInt(json['streakDays']),
      xpToday: _asInt(json['xpToday']),
      dailyGoalCompleted: _asInt(json['dailyGoalCompleted']),
      dailyGoalTarget: _asInt(json['dailyGoalTarget']) == 0
          ? 30
          : _asInt(json['dailyGoalTarget']),
    );
  }
}

class ContinueLearning {
  final String lessonId;
  final String title;
  final String level;
  final int lessonNumber;
  final int progressPercent;

  const ContinueLearning({
    required this.lessonId,
    required this.title,
    required this.level,
    required this.lessonNumber,
    required this.progressPercent,
  });

  double get progressValue => (progressPercent / 100).clamp(0, 1).toDouble();

  factory ContinueLearning.fromJson(Map<String, dynamic> json) {
    return ContinueLearning(
      lessonId: _asString(json['lessonId']),
      title: _asString(json['title']),
      level: _asString(json['level']),
      lessonNumber: _asInt(json['lessonNumber']),
      progressPercent: _asInt(json['progressPercent']),
    );
  }
}

class PracticeSummary {
  final int flashcardCount;
  final int quizQuestionCount;
  final int vocabularyCount;
  final int savedBookmarkCount;
  final String speakingLabel;

  const PracticeSummary({
    required this.flashcardCount,
    required this.quizQuestionCount,
    required this.vocabularyCount,
    required this.savedBookmarkCount,
    required this.speakingLabel,
  });

  factory PracticeSummary.fromJson(Map<String, dynamic> json) {
    return PracticeSummary(
      flashcardCount: _asInt(json['flashcardCount']),
      quizQuestionCount: _asInt(json['quizQuestionCount']),
      vocabularyCount: _asInt(json['vocabularyCount']),
      savedBookmarkCount: _asInt(json['savedBookmarkCount']),
      speakingLabel: _asString(json['speakingLabel']).isEmpty
          ? 'Coming soon'
          : _asString(json['speakingLabel']),
    );
  }
}

class RecommendedCourse {
  final String id;
  final String title;
  final int wordCount;
  final int progressPercent;
  final String category;

  const RecommendedCourse({
    required this.id,
    required this.title,
    required this.wordCount,
    required this.progressPercent,
    required this.category,
  });

  factory RecommendedCourse.fromJson(Map<String, dynamic> json) {
    return RecommendedCourse(
      id: _asString(json['id']),
      title: _asString(json['title']),
      wordCount: _asInt(json['wordCount']),
      progressPercent: _asInt(json['progressPercent']),
      category: _asString(json['category']),
    );
  }
}
