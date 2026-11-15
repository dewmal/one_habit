import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:one_preccent/ai/gateway_llm_client.dart';
import 'package:one_preccent/ai/llm_client.dart';

const _url = 'https://gateway.test/chat';

GatewayLlmClient _client(http.Client http, {String? provider}) =>
    GatewayLlmClient(
      gatewayUrl: _url,
      provider: provider,
      client: http,
      deviceId: () async => 'device-123',
    );

http.Response _reply(String text) =>
    http.Response(jsonEncode({'text': text}), 200);

void main() {
  test('sends device id, instructions and messages, never a key', () async {
    late http.Request sent;
    final client = _client(
      MockClient((req) async {
        sent = req;
        return _reply('{"text":"Good job","wants_bigger":false}');
      }),
    );

    await client.chatReply(
      language: 'English',
      summary: 'Goal: walk.',
      lastMessages: const ['User: hi'],
    );

    expect(sent.url.toString(), _url);
    expect(sent.headers['X-Device-Id'], 'device-123');
    expect(sent.headers.containsKey('Authorization'), isFalse);
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body.containsKey('provider'), isFalse);
    expect(body['instructions'], contains('kind habit coach'));
    expect(body['messages'], [
      {'role': 'user', 'content': contains('Goal: walk.')},
    ]);
  });

  test('chat reply reads text and wants_bigger from the AI JSON', () async {
    final client = _client(
      MockClient(
        (_) async =>
            _reply('Sure. {"text": "Nice work", "wants_bigger": true} Thanks'),
      ),
    );

    final s = await client.chatReply(
      language: 'English',
      summary: '',
      lastMessages: const [],
    );
    expect(s.text, 'Nice work');
    expect(s.wantsBigger, isTrue);
  });

  test('gateway error codes become AiException codes', () async {
    final cases = {429: 'rate_limited', 413: 'too_large', 502: 'ai_500'};
    for (final entry in cases.entries) {
      final client = _client(
        MockClient(
          (_) async =>
              http.Response(jsonEncode({'error': entry.value}), entry.key),
        ),
      );
      await expectLater(
        client.chatReply(
          language: 'English',
          summary: '',
          lastMessages: const [],
        ),
        throwsA(isA<AiException>().having((e) => e.code, 'code', entry.value)),
      );
    }
  });

  test('unreachable gateway gives no_connection', () async {
    final client = _client(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      client.chatReply(
        language: 'English',
        summary: '',
        lastMessages: const [],
      ),
      throwsA(
        isA<AiException>().having((e) => e.code, 'code', 'no_connection'),
      ),
    );
  });

  test(
    'writeTasks returns up to three tasks and rejects empty output',
    () async {
      final ok = _client(
        MockClient(
          (_) async => _reply(
            '{"tasks": ["Put on shoes", "  ", "Walk 2 minutes", "Stand up", "Extra"]}',
          ),
        ),
      );
      final tasks = await ok.writeTasks(
        language: 'English',
        level: 'beginner',
        taskGuide: 'tiny',
      );
      expect(tasks, ['Put on shoes', 'Walk 2 minutes', 'Stand up']);

      final empty = _client(MockClient((_) async => _reply('no json here')));
      await expectLater(
        empty.writeTasks(
          language: 'English',
          level: 'beginner',
          taskGuide: 'tiny',
        ),
        throwsA(isA<AiException>().having((e) => e.code, 'code', 'ai_empty')),
      );
    },
  );
}
