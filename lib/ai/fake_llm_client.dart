import 'llm_client.dart';

/// Fixed answers, no network. Used in tests and when no gateway URL is set.
class FakeLlmClient implements LlmClient {
  @override
  Future<AgentSuggestion> chatReply({
    required String language,
    required String summary,
    required List<String> lastMessages,
  }) async {
    return const AgentSuggestion(text: 'Thanks for telling me. Small steps.');
  }

  @override
  Future<List<String>> writeTasks({
    required String language,
    required String level,
    required String taskGuide,
  }) async {
    return ['Put on your shoes', 'Walk for 2 minutes'];
  }
}
