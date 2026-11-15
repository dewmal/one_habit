/// What the AI suggests. The rules engine checks it before anything changes.
class AgentSuggestion {
  const AgentSuggestion({required this.text, this.wantsBigger = false});

  /// What the coach says.
  final String text;

  /// True if the AI wants a bigger step. Blocked without the user's yes.
  final bool wantsBigger;
}

/// A failed AI call. [code] is one of the gateway codes, or 'no_connection'
/// when the gateway could not be reached at all.
class AiException implements Exception {
  const AiException(this.code);

  final String code;

  @override
  String toString() => 'AiException($code)';
}

/// The service boundary for every AI call. Screens and controllers use this,
/// never http. Today [GatewayLlmClient] sends calls through the gateway. A
/// local model later is a new class that implements this same interface.
abstract class LlmClient {
  /// A coach reply in the General chat.
  Future<AgentSuggestion> chatReply({
    required String language,
    required String summary,
    required List<String> lastMessages,
  });

  /// Tiny daily tasks for the user's level.
  Future<List<String>> writeTasks({
    required String language,
    required String level,
    required String taskGuide,
  });
}
