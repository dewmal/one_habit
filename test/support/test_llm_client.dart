import 'package:one_preccent/ai/llm_client.dart';
import 'package:one_preccent/app/dummy_data.dart';
import 'package:one_preccent/chat/chat_controller.dart';

/// Fixed answers for widget tests. It never touches the network. The app
/// itself has no fake: it always asks the gateway.
class TestLlmClient implements LlmClient {
  @override
  Future<AgentSuggestion> chatReply({
    required String language,
    required String summary,
    required List<ChatTurn> history,
  }) async =>
      const AgentSuggestion(text: 'Thanks for telling me. Small steps.');

  @override
  Future<List<String>> writeTasks({
    required String language,
    required String level,
    required String taskGuide,
  }) async => dummyStepsFor(level);
}

/// Overrides every widget test needs so the chat never calls the gateway.
// The override list type comes from Riverpod; it is not imported here.
// ignore: strict_top_level_inference
testAiOverrides() => [llmProvider.overrideWithValue(TestLlmClient())];
