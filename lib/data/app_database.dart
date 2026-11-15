import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Encrypted on-phone database. The key is random, created once and kept in
/// secure storage. There is no server copy.
///
/// Tables: profile, habit, plan, daily_log, chat_history. Chat history has
/// its own table (the open decision in docs/ROADMAP.md).
class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  static const _keyName = 'habit_agent_db_key';
  static const _fileName = 'habit_agent.db';
  static const _schemaVersion = 1;

  static Future<AppDatabase> open({
    String? path,
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) async {
    final key = await _loadOrCreateKey(storage);
    final dbPath = path ?? p.join(await getDatabasesPath(), _fileName);
    final db = await openDatabase(
      dbPath,
      password: key,
      version: _schemaVersion,
      onCreate: (db, _) async {
        for (final statement in _schema) {
          await db.execute(statement);
        }
      },
    );
    return AppDatabase._(db);
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
    '''CREATE TABLE chat_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chat_id TEXT NOT NULL,
      role TEXT NOT NULL,
      text TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )''',
  ];

  /// Names of every table, used by "My data".
  static const tableNames = [
    'profile',
    'habit',
    'plan',
    'daily_log',
    'chat_history',
  ];

  Future<List<Map<String, Object?>>> rows(String table) => _db.query(table);

  Future<void> close() => _db.close();
}
