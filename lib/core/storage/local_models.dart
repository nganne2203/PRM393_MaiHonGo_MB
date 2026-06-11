import 'package:isar/isar.dart';

part 'local_models.g.dart';

@collection
class LocalLesson {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  late String title;
  late String category;
  late String description;
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

  late String word;
  late String hiragana;
  late String meaningVi;
  late List<String> tags;
  late List<String> examples;
  late String lessonId;
  late String romaji;
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
  late String status;
}
