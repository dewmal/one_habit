import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' show DatabaseFactory;

import 'sql_app_database.dart';

/// Everything the app saves on the phone. Controllers talk to this interface;
/// [SqlAppDatabase] is the encrypted SQLite file behind it. Rows are plain
/// maps with the column names of the data saving doc.
abstract class AppDatabase {
  /// Opens the encrypted database on the phone.
  static Future<AppDatabase> open({
    String? path,
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) => SqlAppDatabase.open(path: path, storage: storage);

  /// Opens a plain database through any sqflite factory (tests only).
  static Future<AppDatabase> openWithFactory(
    DatabaseFactory factory,
    String path,
  ) => SqlAppDatabase.openWithFactory(factory, path);

  /// Names of every table, used by "My data".
  static const tableNames = [
    'profile',
    'habit',
    'plan',
    'daily_log',
    'chat',
    'chat_message',
  ];

  Future<List<Map<String, Object?>>> rows(String table);

  Future<void> close();

  // Habits

  /// Saves a new habit and returns its id. Its General chat is made right
  /// after with [createChat].
  Future<int> createHabit({required String pluginId, required String name});

  Future<List<Map<String, Object?>>> habits();

  Future<void> updateHabit(int id, Map<String, Object?> values);

  /// Removes the habit's messages, chats, plan, daily log and the habit row,
  /// together.
  Future<void> deleteHabit(int id);

  // Chats

  /// Makes a chat. kind is 'general' or 'topic'. Returns the new chat id.
  Future<int> createChat(int habitId, String kind, String title);

  /// All chats of one habit. General comes first, then the newest topic chat.
  Future<List<Map<String, Object?>>> chatsOf(int habitId);

  /// Saves one message and returns its id.
  Future<int> addMessage(
    int chatId,
    String role, {
    String kind = 'text',
    String text = '',
    String? textKey,
    String? cardType,
    String? cardData,
  });

  /// All messages of one chat, oldest first.
  Future<List<Map<String, Object?>>> messagesOf(int chatId);

  /// Saves what the user tapped on a card.
  Future<void> answerCard(int messageId, String answer);

  /// Marks a user message as 'sent' or 'failed'.
  Future<void> setStatus(int messageId, String status);

  /// Deletes the messages of a chat. A topic chat is removed too. The General
  /// chat stays, but empty.
  Future<void> deleteChat(int chatId);

  /// The last text messages of a chat, oldest first. Used to build an AI
  /// request. Cards, fixed phrases and failed messages are left out.
  Future<List<Map<String, Object?>>> recentTextMessages(
    int chatId, {
    int limit = 10,
  });
}
