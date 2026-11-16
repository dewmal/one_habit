import '../ai/llm_client.dart';

/// Turns the last saved text messages of a chat into the turns sent to the
/// AI. Both General and topic chats use this one function.
///
/// The list must start with a user message, and the text must stay under
/// [maxChars] in total, which leaves room for the instructions.
List<ChatTurn> buildHistory(
  List<Map<String, Object?>> rows, {
  int maxChars = 6000,
}) {
  final turns = [
    for (final r in rows)
      ChatTurn(role: r['role'] as String, content: r['text'] as String),
  ];
  int total() => turns.fold(0, (sum, t) => sum + t.content.length);
  while (turns.isNotEmpty &&
      (turns.first.role != 'user' || total() > maxChars)) {
    // Never drop the only message: it is the one being answered.
    if (turns.length == 1) break;
    turns.removeAt(0);
  }
  return turns;
}

/// Asks for a coach reply with the saved [rows] of the chat. If the gateway
/// says `too_large`, it asks once more with only the last 5 messages.
Future<AgentSuggestion> askCoach(
  LlmClient llm, {
  required String language,
  required String summary,
  required List<Map<String, Object?>> rows,
}) async {
  try {
    return await llm.chatReply(
      language: language,
      summary: summary,
      history: buildHistory(rows),
    );
  } on AiException catch (e) {
    if (e.code != 'too_large' || rows.length <= 5) rethrow;
    return llm.chatReply(
      language: language,
      summary: summary,
      history: buildHistory(rows.sublist(rows.length - 5)),
    );
  }
}
