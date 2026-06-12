import 'package:isar/isar.dart';

part 'local_models.g.dart';

@collection
class LocalLesson {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  String? title;
  String? category;
  String? description;
  late bool isOfflineReady;
  late int version;
  late bool downloaded;
  late DateTime lastSyncedAt;
  late List<String> vocabIds;
  late int size;
}

@collection
class LocalVocabulary {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  String? word;
  String? hiragana;
  String? meaningVi;
  late List<String> tags;
  late List<String> examples;
  String? lessonId;
  String? romaji;
  late DateTime lastSyncedAt;
}

@collection
class LocalContentPackage {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String lessonId;

  late int version;
  late int size;
  late DateTime downloadedAt;
  String? status;
}

@collection
class LocalFlashcardSessionResult {
  Id id = Isar.autoIncrement;

  String? lessonId;
  late int totalCards;
  late int learnedCount;
  late int notLearnedCount;
  late int accuracy;
  late List<String> learnedVocabularyIds;
  late List<String> notLearnedVocabularyIds;

  @Index(unique: true, replace: true)
  late DateTime completedAt;

  late bool synced;
}
