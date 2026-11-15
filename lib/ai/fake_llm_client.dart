import '../app/dummy_data.dart';
import 'llm_client.dart';

/// Fixed answers, no network. Used in tests and when no gateway URL is set.
/// Tasks come from the same fixed steps the app uses when the AI is unavailable.
class FakeLlmClient implements LlmClient {
  @override
  Future<AgentSuggestion> chatReply({
    required String language,
    required String summary,
    required List<ChatTurn> history,
  }) async {
    return const AgentSuggestion(text: 'Thanks for telling me. Small steps.');
  }

  @override
  Future<List<String>> writeTasks({
    required String language,
    required String level,
    required String taskGuide,
  }) async {
    return dummyStepsFor(level);
  }
}
