import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../features/bookmarks/models/bookmark.dart';
import '../../features/flashcards/models/flashcard_session.dart';
import '../../features/lessons/models/lesson.dart';
import '../../features/vocabulary/models/vocabulary.dart';
import 'local_models.dart';

class LocalDatabaseService {
  static const _databaseName = 'maihongo_local.db';
  static const _databaseVersion = 1;

  final Database database;
  final String? path;

  const LocalDatabaseService._(this.database, {this.path});

  static Future<LocalDatabaseService> open({
    String? directory,
    DatabaseFactory? databaseFactory,
    String name = _databaseName,
  }) async {
    final factory = databaseFactory ?? _defaultDatabaseFactory();
    final baseDir = directory ?? (await getApplicationSupportDirectory()).path;
    await Directory(baseDir).create(recursive: true);
    final dbPath = p.join(baseDir, name);
    final options = OpenDatabaseOptions(
      version: _databaseVersion,
      onCreate: (db, version) => _createSchema(db),
    );
    final database = await _openDatabaseWithRecovery(factory, dbPath, options);
    return LocalDatabaseService._(database, path: dbPath);
  }

  static Future<Database> _openDatabaseWithRecovery(
    DatabaseFactory factory,
    String dbPath,
    OpenDatabaseOptions options,
  ) async {
    try {
      return await factory.openDatabase(dbPath, options: options);
    } catch (error) {
      final message = error.toString().toLowerCase();
      final recoverable = message.contains('authorization denied') ||
          message.contains('disk i/o') ||
          message.contains('unable to open database file') ||
          message.contains('database is locked') ||
          message.contains('not a database');
      if (!recoverable) rethrow;

      final file = File(dbPath);
      if (await file.exists()) {
        final backupPath =
            '$dbPath.broken-${DateTime.now().millisecondsSinceEpoch}';
        await file.rename(backupPath);
      }
      return factory.openDatabase(dbPath, options: options);
    }
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE lessons (
        server_id TEXT PRIMARY KEY,
        title TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        is_offline_ready INTEGER NOT NULL DEFAULT 0,
        version INTEGER NOT NULL DEFAULT 1,
        downloaded INTEGER NOT NULL DEFAULT 0,
        last_synced_at TEXT NOT NULL,
        vocab_ids_json TEXT NOT NULL DEFAULT '[]',
        size INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE vocabulary (
        server_id TEXT PRIMARY KEY,
        word TEXT NOT NULL DEFAULT '',
        hiragana TEXT NOT NULL DEFAULT '',
        meaning_vi TEXT NOT NULL DEFAULT '',
        tags_json TEXT NOT NULL DEFAULT '[]',
        examples_json TEXT NOT NULL DEFAULT '[]',
        lesson_id TEXT NOT NULL DEFAULT '',
        romaji TEXT NOT NULL DEFAULT '',
        audio_url TEXT NOT NULL DEFAULT '',
        last_synced_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_vocabulary_lesson_id ON vocabulary(lesson_id)',
    );
    await db.execute('''
      CREATE TABLE bookmarks (
        vocab_id TEXT PRIMARY KEY,
        server_id TEXT NOT NULL DEFAULT '',
        word TEXT NOT NULL DEFAULT '',
        hiragana TEXT NOT NULL DEFAULT '',
        meaning_vi TEXT NOT NULL DEFAULT '',
        romaji TEXT NOT NULL DEFAULT '',
        audio_url TEXT NOT NULL DEFAULT '',
        tags_json TEXT NOT NULL DEFAULT '[]',
        examples_json TEXT NOT NULL DEFAULT '[]',
        created_at TEXT,
        last_synced_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE content_packages (
        lesson_id TEXT PRIMARY KEY,
        version INTEGER NOT NULL DEFAULT 1,
        size INTEGER NOT NULL DEFAULT 0,
        downloaded_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'downloaded'
      )
    ''');
    await db.execute('''
      CREATE TABLE flashcard_session_results (
        completed_at TEXT PRIMARY KEY,
        lesson_id TEXT NOT NULL DEFAULT '',
        total_cards INTEGER NOT NULL DEFAULT 0,
        learned_count INTEGER NOT NULL DEFAULT 0,
        not_learned_count INTEGER NOT NULL DEFAULT 0,
        accuracy INTEGER NOT NULL DEFAULT 0,
        learned_vocabulary_ids_json TEXT NOT NULL DEFAULT '[]',
        not_learned_vocabulary_ids_json TEXT NOT NULL DEFAULT '[]',
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static DatabaseFactory _defaultDatabaseFactory() {
    if (Platform.isAndroid || Platform.isIOS) {
      return sqflite.databaseFactory;
    }
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }

  Future<void> close({bool deleteFromDisk = false}) async {
    final dbPath = path;
    await database.close();
    if (deleteFromDisk && dbPath != null) {
      final file = File(dbPath);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> saveLessons(List<Lesson> lessons) async {
    final now = DateTime.now();
    await database.transaction((txn) async {
      for (final lesson in lessons) {
        if (lesson.id.isEmpty) continue;
        final current = await txn.query(
          'lessons',
          columns: ['downloaded'],
          where: 'server_id = ?',
          whereArgs: [lesson.id],
          limit: 1,
        );
        final wasDownloaded =
            current.isNotEmpty && _boolFromDb(current.first['downloaded']);
        await txn.insert(
          'lessons',
          {
            'server_id': lesson.id,
            'title': lesson.title,
            'category': lesson.category,
            'description': lesson.description,
            'is_offline_ready': _boolToDb(lesson.isOfflineReady),
            'version': lesson.version,
            'downloaded': _boolToDb(lesson.downloaded || wasDownloaded),
            'last_synced_at': now.toIso8601String(),
            'vocab_ids_json': jsonEncode(lesson.vocabIds),
            'size': lesson.size,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> saveVocabulary(
    List<Vocabulary> vocabulary, {
    String? lessonId,
  }) async {
    final now = DateTime.now();
    await database.transaction((txn) async {
      for (final vocab in vocabulary) {
        if (vocab.id.isEmpty) continue;
        final current = await txn.query(
          'vocabulary',
          columns: ['lesson_id'],
          where: 'server_id = ?',
          whereArgs: [vocab.id],
          limit: 1,
        );
        final currentLessonId =
            current.isEmpty ? '' : current.first['lesson_id']?.toString() ?? '';
        await txn.insert(
          'vocabulary',
          {
            'server_id': vocab.id,
            'word': vocab.word,
            'hiragana': vocab.hiragana,
            'meaning_vi': vocab.meaningVi,
            'tags_json': jsonEncode(vocab.tags),
            'examples_json': jsonEncode(
              vocab.examples.map((item) => item.toJson()).toList(),
            ),
            'lesson_id': lessonId ?? vocab.lessonId ?? currentLessonId,
            'romaji': vocab.romaji,
            'audio_url': vocab.audioUrl,
            'last_synced_at': now.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Lesson>> getLessons() async {
    final rows = await database.query('lessons', orderBy: 'title ASC');
    return rows.map(_lessonFromRow).toList();
  }

  Future<Lesson?> getLesson(String lessonId) async {
    final rows = await database.query(
      'lessons',
      where: 'server_id = ?',
      whereArgs: [lessonId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _lessonFromRow(rows.first);
  }

  Future<List<Vocabulary>> getVocabulary({String? lessonId}) async {
    final rows = await database.query(
      'vocabulary',
      where: lessonId == null ? null : 'lesson_id = ?',
      whereArgs: lessonId == null ? null : [lessonId],
      orderBy: 'word ASC',
    );
    return rows.map(_vocabularyFromRow).toList();
  }

  Future<List<Vocabulary>> getVocabularyByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await database.query(
      'vocabulary',
      where: 'server_id IN ($placeholders)',
      whereArgs: ids,
      orderBy: 'word ASC',
    );
    return rows.map(_vocabularyFromRow).toList();
  }

  Future<void> saveBookmarks(List<Bookmark> bookmarks) async {
    final incomingIds = bookmarks
        .map((bookmark) => bookmark.vocabId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final now = DateTime.now();
    await database.transaction((txn) async {
      for (final bookmark in bookmarks) {
        if (bookmark.vocabId.isEmpty) continue;
        final existing = await _bookmarkRow(bookmark.vocabId, txn: txn);
        await txn.insert(
          'bookmarks',
          _bookmarkToRow(bookmark, existing: existing, lastSyncedAt: now),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final existingRows = await txn.query('bookmarks', columns: ['vocab_id']);
      for (final row in existingRows) {
        final vocabId = row['vocab_id']?.toString() ?? '';
        if (!incomingIds.contains(vocabId)) {
          await txn.delete(
            'bookmarks',
            where: 'vocab_id = ?',
            whereArgs: [vocabId],
          );
        }
      }
    });
  }

  Future<void> saveBookmark(Bookmark bookmark) async {
    if (bookmark.vocabId.isEmpty) return;
    final existing = await _bookmarkRow(bookmark.vocabId);
    await database.insert(
      'bookmarks',
      _bookmarkToRow(
        bookmark,
        existing: existing,
        lastSyncedAt: DateTime.now(),
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeBookmark(String vocabId) {
    return database.delete(
      'bookmarks',
      where: 'vocab_id = ?',
      whereArgs: [vocabId],
    );
  }

  Future<List<Bookmark>> getBookmarks() async {
    final rows = await database.query(
      'bookmarks',
      orderBy: 'COALESCE(created_at, last_synced_at) DESC',
    );
    return rows.map(_bookmarkFromRow).toList();
  }

  Future<Set<String>> getBookmarkedVocabIds() async {
    final rows = await database.query('bookmarks', columns: ['vocab_id']);
    return rows
        .map((row) => row['vocab_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> markDownloaded({
    required Lesson lesson,
    int? size,
    String status = 'downloaded',
  }) async {
    final now = DateTime.now();
    await database.transaction((txn) async {
      await txn.insert(
        'lessons',
        {
          'server_id': lesson.id,
          'title': lesson.title,
          'category': lesson.category,
          'description': lesson.description,
          'is_offline_ready': _boolToDb(lesson.isOfflineReady),
          'version': lesson.version,
          'downloaded': 1,
          'last_synced_at': now.toIso8601String(),
          'vocab_ids_json': jsonEncode(lesson.vocabIds),
          'size': size ?? lesson.size,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'content_packages',
        {
          'lesson_id': lesson.id,
          'version': lesson.version,
          'size': size ?? lesson.size,
          'downloaded_at': now.toIso8601String(),
          'status': status,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> removeDownloaded(String lessonId) async {
    await database.transaction((txn) async {
      await txn.update(
        'lessons',
        {'downloaded': 0},
        where: 'server_id = ?',
        whereArgs: [lessonId],
      );
      await txn.delete(
        'content_packages',
        where: 'lesson_id = ?',
        whereArgs: [lessonId],
      );
    });
  }

  Future<List<LocalContentPackage>> getContentPackages() async {
    final rows = await database.query(
      'content_packages',
      orderBy: 'downloaded_at DESC',
    );
    return rows.map(_contentPackageFromRow).toList();
  }

  Future<void> saveFlashcardSessionResult(
    FlashcardSessionResult result,
  ) {
    return database.insert(
      'flashcard_session_results',
      {
        'completed_at': result.completedAt.toIso8601String(),
        'lesson_id': result.lessonId,
        'total_cards': result.totalCards,
        'learned_count': result.learnedCount,
        'not_learned_count': result.notLearnedCount,
        'accuracy': result.accuracy,
        'learned_vocabulary_ids_json': jsonEncode(result.learnedVocabularyIds),
        'not_learned_vocabulary_ids_json':
            jsonEncode(result.notLearnedVocabularyIds),
        'synced': _boolToDb(result.synced),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markFlashcardSessionSynced(DateTime completedAt) {
    return database.update(
      'flashcard_session_results',
      {'synced': 1},
      where: 'completed_at = ?',
      whereArgs: [completedAt.toIso8601String()],
    );
  }

  Future<List<LocalFlashcardSessionResult>> getFlashcardSessionResults() async {
    final rows = await database.query(
      'flashcard_session_results',
      orderBy: 'completed_at DESC',
    );
    return rows.map(_flashcardResultFromRow).toList();
  }

  Future<Map<String, Object?>?> _bookmarkRow(
    String vocabId, {
    DatabaseExecutor? txn,
  }) async {
    final rows = await (txn ?? database).query(
      'bookmarks',
      where: 'vocab_id = ?',
      whereArgs: [vocabId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Lesson _lessonFromRow(Map<String, Object?> row) {
    return Lesson(
      id: row['server_id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      category: row['category']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      isOfflineReady: _boolFromDb(row['is_offline_ready']),
      downloadable: _boolFromDb(row['is_offline_ready']),
      version: _intFromDb(row['version'], fallback: 1),
      size: _intFromDb(row['size']),
      vocabIds: _stringListFromJson(row['vocab_ids_json']),
      downloaded: _boolFromDb(row['downloaded']),
      updatedAt: _dateFromDb(row['last_synced_at']),
    );
  }

  Vocabulary _vocabularyFromRow(Map<String, Object?> row) {
    return Vocabulary(
      id: row['server_id']?.toString() ?? '',
      word: row['word']?.toString() ?? '',
      hiragana: row['hiragana']?.toString() ?? '',
      romaji: row['romaji']?.toString() ?? '',
      meaningVi: row['meaning_vi']?.toString() ?? '',
      tags: _stringListFromJson(row['tags_json']),
      examples: _examplesFromJson(row['examples_json']),
      lessonId: (row['lesson_id']?.toString() ?? '').isEmpty
          ? null
          : row['lesson_id']?.toString(),
      audioUrl: row['audio_url']?.toString() ?? '',
      updatedAt: _dateFromDb(row['last_synced_at']),
    );
  }

  Map<String, Object?> _bookmarkToRow(
    Bookmark bookmark, {
    Map<String, Object?>? existing,
    required DateTime lastSyncedAt,
  }) {
    final vocabulary = bookmark.vocabulary;
    return {
      'vocab_id': bookmark.vocabId,
      'server_id': (bookmark.id.isEmpty
          ? _stringFromRow(existing, 'server_id')
          : bookmark.id),
      'word': vocabulary?.word ?? _stringFromRow(existing, 'word'),
      'hiragana': vocabulary?.hiragana ?? _stringFromRow(existing, 'hiragana'),
      'meaning_vi':
          vocabulary?.meaningVi ?? _stringFromRow(existing, 'meaning_vi'),
      'romaji': vocabulary?.romaji ?? _stringFromRow(existing, 'romaji'),
      'audio_url':
          vocabulary?.audioUrl ?? _stringFromRow(existing, 'audio_url'),
      'tags_json': jsonEncode(
        vocabulary?.tags ??
            _stringListFromJson(_valueFromRow(existing, 'tags_json')),
      ),
      'examples_json': jsonEncode(
        vocabulary?.examples.map((item) => item.toJson()).toList() ??
            _jsonList(_valueFromRow(existing, 'examples_json')),
      ),
      'created_at': (bookmark.createdAt ??
              _nullableDateFromDb(_valueFromRow(existing, 'created_at')))
          ?.toIso8601String(),
      'last_synced_at': lastSyncedAt.toIso8601String(),
    };
  }

  Bookmark _bookmarkFromRow(Map<String, Object?> row) {
    final examples = _examplesFromJson(row['examples_json']);
    final hasVocabulary = [
      row['word'],
      row['hiragana'],
      row['romaji'],
      row['meaning_vi'],
    ].any((value) => (value?.toString() ?? '').isNotEmpty);

    return Bookmark(
      id: row['server_id']?.toString() ?? '',
      vocabId: row['vocab_id']?.toString() ?? '',
      vocabulary: hasVocabulary
          ? Vocabulary(
              id: row['vocab_id']?.toString() ?? '',
              word: row['word']?.toString() ?? '',
              hiragana: row['hiragana']?.toString() ?? '',
              romaji: row['romaji']?.toString() ?? '',
              meaningVi: row['meaning_vi']?.toString() ?? '',
              tags: _stringListFromJson(row['tags_json']),
              examples: examples,
              audioUrl: row['audio_url']?.toString() ?? '',
            )
          : null,
      createdAt: _dateFromDb(row['created_at'], fallback: null),
    );
  }

  LocalContentPackage _contentPackageFromRow(Map<String, Object?> row) {
    return LocalContentPackage(
      lessonId: row['lesson_id']?.toString() ?? '',
      version: _intFromDb(row['version'], fallback: 1),
      size: _intFromDb(row['size']),
      downloadedAt: _dateFromDb(row['downloaded_at']),
      status: row['status']?.toString(),
    );
  }

  LocalFlashcardSessionResult _flashcardResultFromRow(
    Map<String, Object?> row,
  ) {
    return LocalFlashcardSessionResult(
      lessonId: (row['lesson_id']?.toString() ?? '').isEmpty
          ? null
          : row['lesson_id']?.toString(),
      totalCards: _intFromDb(row['total_cards']),
      learnedCount: _intFromDb(row['learned_count']),
      notLearnedCount: _intFromDb(row['not_learned_count']),
      accuracy: _intFromDb(row['accuracy']),
      learnedVocabularyIds:
          _stringListFromJson(row['learned_vocabulary_ids_json']),
      notLearnedVocabularyIds:
          _stringListFromJson(row['not_learned_vocabulary_ids_json']),
      completedAt: _dateFromDb(row['completed_at']),
      synced: _boolFromDb(row['synced']),
    );
  }
}

int _boolToDb(bool value) => value ? 1 : 0;

bool _boolFromDb(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString() == '1' || value?.toString() == 'true';
}

int _intFromDb(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime _dateFromDb(Object? value, {DateTime? fallback}) {
  return DateTime.tryParse(value?.toString() ?? '') ??
      fallback ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDateFromDb(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '');
}

List<String> _stringListFromJson(Object? value) {
  return _jsonList(value).map((item) => item.toString()).toList();
}

List<dynamic> _jsonList(Object? value) {
  try {
    final decoded = jsonDecode(value?.toString() ?? '[]');
    if (decoded is List) return decoded;
  } catch (_) {}
  return const [];
}

List<VocabularyExample> _examplesFromJson(Object? value) {
  return _jsonList(value)
      .whereType<Map>()
      .map((item) => VocabularyExample.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ))
      .toList();
}

String _stringFromRow(Map<String, Object?>? row, String key) {
  return row == null ? '' : row[key]?.toString() ?? '';
}

Object? _valueFromRow(Map<String, Object?>? row, String key) {
  return row == null ? null : row[key];
}
