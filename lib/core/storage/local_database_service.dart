import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/bookmarks/models/bookmark.dart';
import '../../features/lessons/models/lesson.dart';
import '../../features/flashcards/models/flashcard_session.dart';
import '../../features/vocabulary/models/vocabulary.dart';
import 'local_models.dart';

class LocalDatabaseService {
  final Isar isar;

  const LocalDatabaseService._(this.isar);

  static Future<LocalDatabaseService> open({String? directory}) async {
    final dir = directory ?? (await getApplicationDocumentsDirectory()).path;
    final isar = await Isar.open(
      [
        LocalLessonSchema,
        LocalVocabularySchema,
        LocalBookmarkSchema,
        LocalContentPackageSchema,
        LocalFlashcardSessionResultSchema,
      ],
      directory: dir,
    );
    return LocalDatabaseService._(isar);
  }

  static LocalDatabaseService fromIsar(Isar isar) =>
      LocalDatabaseService._(isar);

  Future<void> saveLessons(List<Lesson> lessons) async {
    final existing = {
      for (final item in await isar.localLessons.where().findAll())
        item.serverId: item,
    };
    final now = DateTime.now();

    await isar.writeTxn(() async {
      for (final lesson in lessons) {
        if (lesson.id.isEmpty) continue;
        final current = existing[lesson.id];
        final local = LocalLesson()
          ..id = current?.id ?? Isar.autoIncrement
          ..serverId = lesson.id
          ..title = lesson.title
          ..category = lesson.category
          ..description = lesson.description
          ..isOfflineReady = lesson.isOfflineReady
          ..version = lesson.version
          ..downloaded = lesson.downloaded || (current?.downloaded ?? false)
          ..lastSyncedAt = now
          ..vocabIds = lesson.vocabIds
          ..size = lesson.size;
        await isar.localLessons.put(local);
      }
    });
  }

  Future<void> saveVocabulary(
    List<Vocabulary> vocabulary, {
    String? lessonId,
  }) async {
    final existing = {
      for (final item in await isar.localVocabularys.where().findAll())
        item.serverId: item,
    };
    final now = DateTime.now();

    await isar.writeTxn(() async {
      for (final vocab in vocabulary) {
        if (vocab.id.isEmpty) continue;
        final current = existing[vocab.id];
        final examples = vocab.examples
            .map((example) => jsonEncode(example.toJson()))
            .toList();
        final local = LocalVocabulary()
          ..id = current?.id ?? Isar.autoIncrement
          ..serverId = vocab.id
          ..word = vocab.word
          ..hiragana = vocab.hiragana
          ..meaningVi = vocab.meaningVi
          ..tags = vocab.tags
          ..examples = examples
          ..lessonId = lessonId ?? vocab.lessonId ?? current?.lessonId ?? ''
          ..romaji = vocab.romaji
          ..lastSyncedAt = now;
        await isar.localVocabularys.put(local);
      }
    });
  }

  Future<List<Lesson>> getLessons() async {
    final lessons = await isar.localLessons.where().findAll();
    lessons.sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
    return lessons.map(_lessonFromLocal).toList();
  }

  Future<Lesson?> getLesson(String lessonId) async {
    final lessons = await getLessons();
    for (final lesson in lessons) {
      if (lesson.id == lessonId) return lesson;
    }
    return null;
  }

  Future<List<Vocabulary>> getVocabulary({String? lessonId}) async {
    final vocabulary = await isar.localVocabularys.where().findAll();
    final filtered = lessonId == null
        ? vocabulary
        : vocabulary.where((item) => item.lessonId == lessonId).toList();
    filtered.sort((a, b) => (a.word ?? '').compareTo(b.word ?? ''));
    return filtered.map(_vocabularyFromLocal).toList();
  }

  Future<List<Vocabulary>> getVocabularyByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final idSet = ids.toSet();
    final vocabulary = await isar.localVocabularys.where().findAll();
    return vocabulary
        .where((item) => idSet.contains(item.serverId))
        .map(_vocabularyFromLocal)
        .toList();
  }

  Future<void> saveBookmarks(List<Bookmark> bookmarks) async {
    final existing = {
      for (final item in await isar.localBookmarks.where().findAll())
        item.vocabId: item,
    };
    final incomingIds = bookmarks
        .map((bookmark) => bookmark.vocabId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final now = DateTime.now();

    await isar.writeTxn(() async {
      for (final bookmark in bookmarks) {
        if (bookmark.vocabId.isEmpty) continue;
        await isar.localBookmarks.put(
          _bookmarkToLocal(
            bookmark,
            existing: existing[bookmark.vocabId],
            lastSyncedAt: now,
          ),
        );
      }
      for (final local in existing.values) {
        if (!incomingIds.contains(local.vocabId)) {
          await isar.localBookmarks.delete(local.id);
        }
      }
    });
  }

  Future<void> saveBookmark(Bookmark bookmark) async {
    if (bookmark.vocabId.isEmpty) return;
    final existing = await isar.localBookmarks
        .where()
        .vocabIdEqualTo(bookmark.vocabId)
        .findFirst();
    final local = _bookmarkToLocal(
      bookmark,
      existing: existing,
      lastSyncedAt: DateTime.now(),
    );

    await isar.writeTxn(() async {
      await isar.localBookmarks.put(local);
    });
  }

  Future<void> removeBookmark(String vocabId) async {
    final bookmark =
        await isar.localBookmarks.where().vocabIdEqualTo(vocabId).findFirst();
    if (bookmark == null) return;
    await isar.writeTxn(() async {
      await isar.localBookmarks.delete(bookmark.id);
    });
  }

  Future<List<Bookmark>> getBookmarks() async {
    final bookmarks = await isar.localBookmarks.where().findAll();
    bookmarks.sort((a, b) {
      final aDate = a.createdAt ?? a.lastSyncedAt;
      final bDate = b.createdAt ?? b.lastSyncedAt;
      return bDate.compareTo(aDate);
    });
    return bookmarks.map(_bookmarkFromLocal).toList();
  }

  Future<Set<String>> getBookmarkedVocabIds() async {
    final bookmarks = await isar.localBookmarks.where().findAll();
    return bookmarks
        .map((bookmark) => bookmark.vocabId)
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> markDownloaded({
    required Lesson lesson,
    int? size,
    String status = 'downloaded',
  }) async {
    final lessons = await isar.localLessons.where().findAll();
    final current =
        lessons.where((item) => item.serverId == lesson.id).firstOrNull;

    await isar.writeTxn(() async {
      final local = LocalLesson()
        ..id = current?.id ?? Isar.autoIncrement
        ..serverId = lesson.id
        ..title = lesson.title
        ..category = lesson.category
        ..description = lesson.description
        ..isOfflineReady = lesson.isOfflineReady
        ..version = lesson.version
        ..downloaded = true
        ..lastSyncedAt = DateTime.now()
        ..vocabIds = lesson.vocabIds
        ..size = size ?? lesson.size;
      await isar.localLessons.put(local);

      final packages = await isar.localContentPackages.where().findAll();
      final currentPackage =
          packages.where((item) => item.lessonId == lesson.id).firstOrNull;
      final contentPackage = LocalContentPackage()
        ..id = currentPackage?.id ?? Isar.autoIncrement
        ..lessonId = lesson.id
        ..version = lesson.version
        ..size = size ?? lesson.size
        ..downloadedAt = DateTime.now()
        ..status = status;
      await isar.localContentPackages.put(contentPackage);
    });
  }

  Future<void> removeDownloaded(String lessonId) async {
    final lessons = await isar.localLessons.where().findAll();
    final packages = await isar.localContentPackages.where().findAll();
    final lesson =
        lessons.where((item) => item.serverId == lessonId).firstOrNull;
    final package =
        packages.where((item) => item.lessonId == lessonId).firstOrNull;

    await isar.writeTxn(() async {
      if (lesson != null) {
        lesson.downloaded = false;
        await isar.localLessons.put(lesson);
      }
      if (package != null) {
        await isar.localContentPackages.delete(package.id);
      }
    });
  }

  Future<List<LocalContentPackage>> getContentPackages() async {
    final packages = await isar.localContentPackages.where().findAll();
    packages.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    return packages;
  }

  Future<void> saveFlashcardSessionResult(
    FlashcardSessionResult result,
  ) async {
    final existing = await isar.localFlashcardSessionResults
        .where()
        .completedAtEqualTo(result.completedAt)
        .findFirst();

    final local = LocalFlashcardSessionResult()
      ..id = existing?.id ?? Isar.autoIncrement
      ..lessonId = result.lessonId
      ..totalCards = result.totalCards
      ..learnedCount = result.learnedCount
      ..notLearnedCount = result.notLearnedCount
      ..accuracy = result.accuracy
      ..learnedVocabularyIds = result.learnedVocabularyIds
      ..notLearnedVocabularyIds = result.notLearnedVocabularyIds
      ..completedAt = result.completedAt
      ..synced = result.synced;

    await isar.writeTxn(() async {
      await isar.localFlashcardSessionResults.put(local);
    });
  }

  Future<void> markFlashcardSessionSynced(DateTime completedAt) async {
    final result = await isar.localFlashcardSessionResults
        .where()
        .completedAtEqualTo(completedAt)
        .findFirst();
    if (result == null) return;

    await isar.writeTxn(() async {
      result.synced = true;
      await isar.localFlashcardSessionResults.put(result);
    });
  }

  Future<List<LocalFlashcardSessionResult>> getFlashcardSessionResults() async {
    final results = await isar.localFlashcardSessionResults.where().findAll();
    results.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return results;
  }

  Lesson _lessonFromLocal(LocalLesson local) {
    return Lesson(
      id: local.serverId,
      title: local.title ?? '',
      category: local.category ?? '',
      description: local.description ?? '',
      isOfflineReady: local.isOfflineReady,
      downloadable: local.isOfflineReady,
      version: local.version,
      size: local.size,
      vocabIds: local.vocabIds,
      downloaded: local.downloaded,
      updatedAt: local.lastSyncedAt,
    );
  }

  Vocabulary _vocabularyFromLocal(LocalVocabulary local) {
    final examples = local.examples
        .map((raw) {
          try {
            return VocabularyExample.fromJson(jsonDecode(raw));
          } catch (_) {
            return null;
          }
        })
        .whereType<VocabularyExample>()
        .toList();

    return Vocabulary(
      id: local.serverId,
      word: local.word ?? '',
      hiragana: local.hiragana ?? '',
      romaji: local.romaji ?? '',
      meaningVi: local.meaningVi ?? '',
      tags: local.tags,
      examples: examples,
      lessonId: (local.lessonId ?? '').isEmpty ? null : local.lessonId,
      updatedAt: local.lastSyncedAt,
    );
  }

  LocalBookmark _bookmarkToLocal(
    Bookmark bookmark, {
    LocalBookmark? existing,
    required DateTime lastSyncedAt,
  }) {
    final vocabulary = bookmark.vocabulary;
    final examples = vocabulary?.examples
            .map((example) => jsonEncode(example.toJson()))
            .toList() ??
        existing?.examples ??
        const <String>[];

    return LocalBookmark()
      ..id = existing?.id ?? Isar.autoIncrement
      ..serverId = bookmark.id.isEmpty ? existing?.serverId : bookmark.id
      ..vocabId = bookmark.vocabId
      ..word = vocabulary?.word ?? existing?.word
      ..hiragana = vocabulary?.hiragana ?? existing?.hiragana
      ..meaningVi = vocabulary?.meaningVi ?? existing?.meaningVi
      ..romaji = vocabulary?.romaji ?? existing?.romaji
      ..audioUrl = vocabulary?.audioUrl ?? existing?.audioUrl
      ..tags = vocabulary?.tags ?? existing?.tags ?? const <String>[]
      ..examples = examples
      ..createdAt = bookmark.createdAt ?? existing?.createdAt
      ..lastSyncedAt = lastSyncedAt;
  }

  Bookmark _bookmarkFromLocal(LocalBookmark local) {
    final examples = local.examples
        .map((raw) {
          try {
            return VocabularyExample.fromJson(jsonDecode(raw));
          } catch (_) {
            return null;
          }
        })
        .whereType<VocabularyExample>()
        .toList();

    final hasVocabulary = [
      local.word,
      local.hiragana,
      local.romaji,
      local.meaningVi,
    ].any((value) => (value ?? '').isNotEmpty);

    return Bookmark(
      id: local.serverId ?? '',
      vocabId: local.vocabId,
      vocabulary: hasVocabulary
          ? Vocabulary(
              id: local.vocabId,
              word: local.word ?? '',
              hiragana: local.hiragana ?? '',
              romaji: local.romaji ?? '',
              meaningVi: local.meaningVi ?? '',
              tags: local.tags,
              examples: examples,
              audioUrl: local.audioUrl ?? '',
            )
          : null,
      createdAt: local.createdAt,
    );
  }
}
