import 'dart:convert';

import 'package:http/http.dart' as http;

import 'device_id.dart';
import 'llm_client.dart';

/// Talks to the gateway at [gatewayUrl] (the full URL ending in /chat).
/// The app holds no AI key. Every call sends the install's device id.
class GatewayLlmClient implements LlmClient {
  GatewayLlmClient({
    required this.gatewayUrl,
    this.provider,
    http.Client? client,
    Future<String> Function()? deviceId,
  }) : _client = client ?? http.Client(),
       _deviceId = deviceId ?? loadOrCreateDeviceId;

  final String gatewayUrl;

  /// Null means the gateway uses its default provider.
  final String? provider;

  final http.Client _client;
  final Future<String> Function() _deviceId;

  /// Sends one request and returns the AI's raw text.
  /// Throws [AiException] with the gateway's error code.
  Future<String> _ask(
    String instructions,
    List<Map<String, String>> messages,
  ) async {
    final body = <String, Object?>{
      'instructions': instructions,
      'messages': messages,
      if (provider != null) 'provider': provider,
    };

    final http.Response response;
    try {
      final deviceId = await _deviceId();
      response = await _client
          .post(
            Uri.parse(gatewayUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Device-Id': deviceId,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } on Exception {
      throw const AiException('no_connection');
    }

    // utf8.decode keeps Sinhala letters correct.
    final data = _decode(response.bodyBytes);
    if (response.statusCode != 200) {
      final code = data?['error'];
      throw AiException(code is String ? code : 'ai_error');
    }
    final text = data?['text'];
    if (text is! String || text.trim().isEmpty) {
      throw const AiException('ai_empty');
    }
    return text;
  }

  Map<String, dynamic>? _decode(List<int> bytes) {
    try {
      final data = jsonDecode(utf8.decode(bytes));
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null;
    }
  }

  /// The AI sometimes adds words around the JSON. Keep only the { ... } part.
  Map<String, dynamic> _readJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1) return {};
    try {
      return jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<AgentSuggestion> chatReply({
    required String language,
    required String summary,
    required List<String> lastMessages,
  }) async {
    final instructions =
        '''
You are a kind habit coach. Reply in $language. Keep it under 3 short sentences.
Never use guilt, pressure or urgency. Never give medical or diet advice.
Reply only with JSON like this:
{"text": "your reply", "wants_bigger": false}
Set wants_bigger to true only if you think the user is ready for a bigger step.
''';

    final raw = await _ask(instructions, [
      {
        'role': 'user',
        'content':
            'Summary: $summary\n\nLast messages:\n'
            '${lastMessages.join('\n')}',
      },
    ]);
    final json = _readJson(raw);

    return AgentSuggestion(
      text: (json['text'] as String?) ?? raw,
      wantsBigger: json['wants_bigger'] == true,
    );
  }

  @override
  Future<List<String>> writeTasks({
    required String language,
    required String level,
    required String taskGuide,
  }) async {
    final instructions =
        '''
You write tiny daily tasks for a habit. Write in $language.
$taskGuide
Reply only with JSON like this:
{"tasks": ["task one", "task two"]}
Give 1 to 3 tasks. Each task must be very small.
''';

    final raw = await _ask(instructions, [
      {'role': 'user', 'content': 'User level: $level'},
    ]);
    final tasks = _readJson(raw)['tasks'];

    if (tasks is List) {
      final clean = [
        for (final t in tasks)
          if (t is String && t.trim().isNotEmpty) t.trim(),
      ];
      if (clean.isNotEmpty) return clean.take(3).toList();
    }
    throw const AiException('ai_empty');
  }
}
