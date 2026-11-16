import 'dart:convert';

import 'package:one_preccent/data/app_database.dart';

/// A pure Dart copy of [AppDatabase] for widget tests. It follows the same
/// rules as the SQL version (chat order, the General chat is never removed,
/// failed messages are left out of AI requests). The SQL itself is tested in
/// test/data with sqflite_common_ffi.
class MemoryAppDatabase implements AppDatabase {
  final Map<String, List<Map<String, Object?>>> tables = {
    for (final name in AppDatabase.tableNames) name: [],
  };
  final Map<String, int> _ids = {};
  int _clock = 0;

  int _next(String table) => _ids[table] = (_ids[table] ?? 0) + 1;

  /// Time only has to go up, so tests never sleep.
  int _now() => ++_clock;

  Map<String, Object?> _find(String table, int id) =>
      tables[table]!.firstWhere((r) => r['id'] == id);

  @override
  Future<List<Map<String, Object?>>> rows(String table) async => [
    for (final r in tables[table]!) {...r},
  ];

  @override
  Future<void> close() async {}

  @override
  Future<void> wipe() async {
    for (final table in tables.values) {
      table.clear();
    }
  }

  @override
  Future<int> createHabit({
    required String pluginId,
    required String name,
  }) async {
    final id = _next('habit');
    tables['habit']!.add({
      'id': id,
      'plugin_id': pluginId,
      'name': name,
      'goal': null,
      'target': null,
      'level': null,
      'safety_result': null,
      'paused': 0,
      'pending_step_up': 0,
    });
    return id;
  }

  @override
  Future<List<Map<String, Object?>>> habits() => rows('habit');

  @override
  Future<void> updateHabit(int id, Map<String, Object?> values) async =>
      _find('habit', id).addAll(values);

  @override
  Future<void> deleteHabit(int id) async {
    final chatIds = [
      for (final c in tables['chat']!)
        if (c['habit_id'] == id) c['id'],
    ];
    tables['chat_message']!.removeWhere((m) => chatIds.contains(m['chat_id']));
    tables['chat']!.removeWhere((c) => c['habit_id'] == id);
    tables['plan']!.removeWhere((r) => r['habit_id'] == id);
    tables['daily_log']!.removeWhere((r) => r['habit_id'] == id);
    tables['habit']!.removeWhere((h) => h['id'] == id);
  }

  @override
  Future<int> createChat(int habitId, String kind, String title) async {
    final id = _next('chat');
    final now = _now();
    tables['chat']!.add({
      'id': id,
      'habit_id': habitId,
      'kind': kind,
      'title': title,
      'summary': '',
      'summary_upto': 0,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  @override
  Future<List<Map<String, Object?>>> chatsOf(int habitId) async {
    final chats = [
      for (final c in tables['chat']!)
        if (c['habit_id'] == habitId) {...c},
    ];
    chats.sort((a, b) {
      final kind = (a['kind'] as String).compareTo(b['kind'] as String);
      if (kind != 0) return kind;
      final time = (b['updated_at'] as int).compareTo(a['updated_at'] as int);
      return time != 0 ? time : (b['id'] as int).compareTo(a['id'] as int);
    });
    return chats;
  }

  @override
  Future<int> addMessage(
    int chatId,
    String role, {
    String kind = 'text',
    String text = '',
    String? textKey,
    String? cardType,
    String? cardData,
  }) async {
    final id = _next('chat_message');
    final now = _now();
    tables['chat_message']!.add({
      'id': id,
      'chat_id': chatId,
      'role': role,
      'kind': kind,
      'text': text,
      'text_key': textKey,
      'card_type': cardType,
      'card_data': cardData,
      'card_answer': null,
      'status': 'sent',
      'created_at': now,
    });
    _find('chat', chatId)['updated_at'] = now;
    return id;
  }

  @override
  Future<List<Map<String, Object?>>> messagesOf(int chatId) async => [
    for (final m in tables['chat_message']!)
      if (m['chat_id'] == chatId) {...m},
  ];

  @override
  Future<void> answerCard(int messageId, String answer) async =>
      _find('chat_message', messageId)['card_answer'] = answer;

  @override
  Future<void> setStatus(int messageId, String status) async =>
      _find('chat_message', messageId)['status'] = status;

  @override
  Future<void> deleteChat(int chatId) async {
    tables['chat_message']!.removeWhere((m) => m['chat_id'] == chatId);
    tables['chat']!.removeWhere(
      (c) => c['id'] == chatId && c['kind'] == 'topic',
    );
  }

  @override
  Future<List<Map<String, Object?>>> recentTextMessages(
    int chatId, {
    int limit = 10,
  }) async {
    final all = [
      for (final m in tables['chat_message']!)
        if (m['chat_id'] == chatId &&
            m['kind'] == 'text' &&
            m['status'] == 'sent')
          {...m},
    ];
    return all.length <= limit ? all : all.sublist(all.length - limit);
  }

  @override
  Future<Map<String, Object?>?> planOf(int habitId) async {
    for (final r in tables['plan']!) {
      if (r['habit_id'] == habitId) return {...r};
    }
    return null;
  }

  @override
  Future<void> savePlan(
    int habitId, {
    required int stageIndex,
    required List<String> tasks,
  }) async {
    tables['plan']!.removeWhere((r) => r['habit_id'] == habitId);
    tables['plan']!.add({
      'id': _next('plan'),
      'habit_id': habitId,
      'stage_index': stageIndex,
      'tasks': jsonEncode(tasks),
    });
  }

  @override
  Future<void> clearPlan(int habitId) async =>
      tables['plan']!.removeWhere((r) => r['habit_id'] == habitId);

  @override
  Future<List<Map<String, Object?>>> logsOf(int habitId) async {
    final logs = [
      for (final r in tables['daily_log']!)
        if (r['habit_id'] == habitId) {...r},
    ];
    logs.sort(
      (a, b) => (b['log_date'] as String).compareTo(a['log_date'] as String),
    );
    return logs;
  }

  @override
  Future<void> saveDay(
    int habitId, {
    required String date,
    required String results,
    String? feeling,
  }) async {
    tables['daily_log']!.removeWhere(
      (r) => r['habit_id'] == habitId && r['log_date'] == date,
    );
    tables['daily_log']!.add({
      'id': _next('daily_log'),
      'habit_id': habitId,
      'log_date': date,
      'results': results,
      'feeling': feeling,
    });
  }

  @override
  Future<void> clearLog(int habitId) async =>
      tables['daily_log']!.removeWhere((r) => r['habit_id'] == habitId);

  @override
  Future<Map<String, Object?>?> profile() async =>
      tables['profile']!.isEmpty ? null : {...tables['profile']!.first};

  @override
  Future<void> saveProfile(Map<String, Object?> values) async =>
      tables['profile']!
        ..clear()
        ..add({...values, 'id': 1});

  @override
  Future<void> clearProfile() async => tables['profile']!.clear();
}
