import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Encrypted on-phone database. The key is random, created once and kept in
/// secure storage. There is no server copy.
///
/// Tables: profile, habit, plan, daily_log, chat, chat_message. A habit has
/// many chats and a chat has many messages (docs/One habit Data Saving and
/// Chat Management (Flutter).md).
class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  static const _keyName = 'habit_agent_db_key';
  static const _fileName = 'habit_agent.db';
  static const _schemaVersion = 2;

  /// Opens the database. If the key is missing or the file cannot be opened,
  /// the file is treated as a fresh install: it is deleted and made again, and
  /// the app shows Welcome.
  static Future<AppDatabase> open({
    String? path,
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), _fileName);
    String? existingKey;
    try {
      existingKey = await storage.read(key: _keyName);
    } catch (_) {}
    if (existingKey == null) {
      // A file without its key can never be opened.
      await deleteDatabase(dbPath);
    }
    try {
      return await _openAt(dbPath, storage);
    } catch (_) {
      await deleteDatabase(dbPath);
      await storage.delete(key: _keyName);
      return _openAt(dbPath, storage);
    }
  }

  static Future<AppDatabase> _openAt(
    String dbPath,
    FlutterSecureStorage storage,
  ) async {
    final key = await _loadOrCreateKey(storage);
    final db = await openDatabase(
      dbPath,
      password: key,
      version: _schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return AppDatabase._(db);
  }

  /// Opens a plain, unencrypted database through any sqflite factory. Tests
  /// use it with an in-memory sqflite_common_ffi database.
  static Future<AppDatabase> openWithFactory(
    DatabaseFactory factory,
    String path,
  ) async => AppDatabase._(
    await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        singleInstance: false,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    ),
  );

  static Future<void> _onCreate(Database db, int version) async {
    for (final statement in [..._schema, ..._version2]) {
      await db.execute(statement);
    }
  }

  /// Version 1 phones have an empty chat_history table, so it is dropped.
  static Future<void> _onUpgrade(Database db, int oldVersion, int _) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS chat_history');
      for (final statement in _version2) {
        await db.execute(statement);
      }
    }
  }

  static Future<String> _loadOrCreateKey(FlutterSecureStorage storage) async {
    final existing = await storage.read(key: _keyName);
    if (existing != null) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final key = base64Encode(bytes);
    await storage.write(key: _keyName, value: key);
    return key;
  }

  static const _schema = [
    '''CREATE TABLE profile (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      language TEXT NOT NULL,
      daily_limit INTEGER NOT NULL DEFAULT 2,
      morning_time TEXT,
      evening_time TEXT,
      quiet_start TEXT,
      quiet_end TEXT
    )''',
    '''CREATE TABLE habit (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      plugin_id TEXT NOT NULL,
      goal TEXT,
      target TEXT,
      level TEXT,
      safety_result TEXT,
      paused INTEGER NOT NULL DEFAULT 0
    )''',
    '''CREATE TABLE plan (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      habit_id INTEGER NOT NULL,
      stage_index INTEGER NOT NULL DEFAULT 0,
      tasks TEXT NOT NULL DEFAULT '[]'
    )''',
    '''CREATE TABLE daily_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      habit_id INTEGER NOT NULL,
      log_date TEXT NOT NULL,
      results TEXT NOT NULL,
      feeling TEXT
    )''',
  ];

  /// Added in schema version 2. New installs run these after [_schema].
  static const _version2 = [
    '''CREATE TABLE chat (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      habit_id INTEGER NOT NULL,
      kind TEXT NOT NULL,
      title TEXT NOT NULL,
      summary TEXT NOT NULL DEFAULT '',
      summary_upto INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )''',
    '''CREATE TABLE chat_message (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chat_id INTEGER NOT NULL,
      role TEXT NOT NULL,
      kind TEXT NOT NULL DEFAULT 'text',
      text TEXT NOT NULL DEFAULT '',
      text_key TEXT,
      card_type TEXT,
      card_data TEXT,
      card_answer TEXT,
      status TEXT NOT NULL DEFAULT 'sent',
      created_at INTEGER NOT NULL
    )''',
    'CREATE INDEX chat_by_habit ON chat (habit_id)',
    'CREATE INDEX message_by_chat ON chat_message (chat_id, id)',
    'ALTER TABLE habit ADD COLUMN name TEXT',
    'ALTER TABLE habit ADD COLUMN pending_step_up INTEGER NOT NULL DEFAULT 0',
  ];

  /// Names of every table, used by "My data".
  static const tableNames = [
    'profile',
    'habit',
    'plan',
    'daily_log',
    'chat',
    'chat_message',
  ];

  Future<List<Map<String, Object?>>> rows(String table) => _db.query(table);

  int _now() => DateTime.now().millisecondsSinceEpoch;

  /// Makes a chat. kind is 'general' or 'topic'. Returns the new chat id.
  Future<int> createChat(int habitId, String kind, String title) {
    final now = _now();
    return _db.insert('chat', {
      'habit_id': habitId,
      'kind': kind,
      'title': title,
      'created_at': now,
      'updated_at': now,
    });
  }

  /// All chats of one habit. General comes first, then the newest topic chat.
  /// ('general' sorts before 'topic' by alphabet.)
  Future<List<Map<String, Object?>>> chatsOf(int habitId) => _db.query(
    'chat',
    where: 'habit_id = ?',
    whereArgs: [habitId],
    orderBy: 'kind ASC, updated_at DESC, id DESC',
  );

  /// Saves one message and returns its id.
  Future<int> addMessage(
    int chatId,
    String role, {
    String kind = 'text',
    String text = '',
    String? textKey,
    String? cardType,
    String? cardData,
  }) async {
    final now = _now();
    final id = await _db.insert('chat_message', {
      'chat_id': chatId,
      'role': role,
      'kind': kind,
      'text': text,
      'text_key': textKey,
      'card_type': cardType,
      'card_data': cardData,
      'created_at': now,
    });
    await _db.update(
      'chat',
      {'updated_at': now},
      where: 'id = ?',
      whereArgs: [chatId],
    );
    return id;
  }

  /// All messages of one chat, oldest first.
  Future<List<Map<String, Object?>>> messagesOf(int chatId) => _db.query(
    'chat_message',
    where: 'chat_id = ?',
    whereArgs: [chatId],
    orderBy: 'id',
  );

  /// Saves what the user tapped on a card.
  Future<void> answerCard(int messageId, String answer) => _db.update(
    'chat_message',
    {'card_answer': answer},
    where: 'id = ?',
    whereArgs: [messageId],
  );

  /// Marks a user message as 'sent' or 'failed'.
  Future<void> setStatus(int messageId, String status) => _db.update(
    'chat_message',
    {'status': status},
    where: 'id = ?',
    whereArgs: [messageId],
  );

  /// Deletes the messages of a chat. A topic chat is removed too.
  /// The General chat stays, but empty.
  Future<void> deleteChat(int chatId) async {
    await _db.delete(
      'chat_message',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
    await _db.delete(
      'chat',
      where: "id = ? AND kind = 'topic'",
      whereArgs: [chatId],
    );
  }

  /// The last text messages of a chat, oldest first. Used to build an AI
  /// request. Cards, fixed phrases and failed messages are left out.
  Future<List<Map<String, Object?>>> recentTextMessages(
    int chatId, {
    int limit = 10,
  }) async {
    final rows = await _db.query(
      'chat_message',
      where: "chat_id = ? AND kind = 'text' AND status = 'sent'",
      whereArgs: [chatId],
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.reversed.toList();
  }

  Future<void> close() => _db.close();
}
