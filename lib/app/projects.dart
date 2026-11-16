import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/llm_client.dart';
import '../chat/chat_controller.dart';
import '../chat/history.dart';
import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/startup.dart';
import '../i18n/language.dart';
import '../plugins/fitness_plugin.dart';
import 'rules.dart';
import 'tabs.dart';

/// One chat inside a habit. The General chat is pinned and the only one
/// that can change the plan. [id] is the row id of the chat table.
class ChatInfo {
  const ChatInfo({required this.id, required this.title, this.general = false});

  final int id;
  final String title;
  final bool general;
}

/// One habit (project). [id] is the row id of the habit table.
class Project {
  const Project({required this.id, required this.name, required this.chats});

  final int id;
  final String name;
  final List<ChatInfo> chats;

  ChatInfo get generalChat => chats.firstWhere((c) => c.general);
}

class ProjectsState {
  const ProjectsState({
    required this.projects,
    required this.currentId,
    required this.currentChatId,
  });

  final List<Project> projects;
  final int currentId;
  final int currentChatId;

  bool get hasProject => projects.isNotEmpty;

  /// An empty placeholder while no habit exists (before Start, or for a
  /// frame after "Delete everything"). Screens that need a habit are not
  /// shown then.
  static const _none = Project(
    id: 0,
    name: '',
    chats: [ChatInfo(id: 0, title: 'General', general: true)],
  );

  Project get current =>
      projects.where((p) => p.id == currentId).firstOrNull ?? _none;

  ChatInfo get currentChat => current.chats.firstWhere(
    (c) => c.id == currentChatId,
    orElse: () => current.generalChat,
  );
}

/// Topics offered on the New chat screen (plugin topics for now).
const newChatTopics = ['Exercise', 'Diet', 'Health issues'];

/// Builds the projects from the habit and chat rows read at start.
List<Project> projectsFromRows(
  List<Map<String, Object?>> habits,
  List<Map<String, Object?>> chats,
) => [
  for (final h in habits)
    Project(
      id: h['id'] as int,
      name:
          (h['name'] as String?) ??
          resolve(fitnessPlugin.projectName, AppLanguage.en),
      chats: [
        for (final c in chats)
          if (c['habit_id'] == h['id'])
            ChatInfo(
              id: c['id'] as int,
              title: c['title'] as String,
              general: c['kind'] == 'general',
            ),
      ],
    ),
];

class ProjectsController extends Notifier<ProjectsState> {
  @override
  ProjectsState build() {
    final start = ref.watch(startupProvider);
    final projects = projectsFromRows(start.habits, start.chats);
    return ProjectsState(
      projects: projects,
      currentId: projects.isEmpty ? 0 : projects.first.id,
      currentChatId: projects.isEmpty ? 0 : projects.first.generalChat.id,
    );
  }

  AppDatabase get _db => ref.read(databaseProvider);

  /// Makes the first habit and its General chat if there is none yet. The
  /// habit row is saved first, then the General chat.
  Future<void> ensureHabit() async {
    if (state.hasProject) return;
    final name = resolve(fitnessPlugin.projectName, AppLanguage.en);
    final habitId = await _db.createHabit(
      pluginId: fitnessPlugin.id,
      name: name,
    );
    final chatId = await _db.createChat(habitId, 'general', 'General');
    state = ProjectsState(
      projects: [
        Project(
          id: habitId,
          name: name,
          chats: [ChatInfo(id: chatId, title: 'General', general: true)],
        ),
      ],
      currentId: habitId,
      currentChatId: chatId,
    );
  }

  /// Tapping a habit makes it the current project, on its General chat.
  void selectProject(int id) {
    final project = state.projects.firstWhere((p) => p.id == id);
    state = ProjectsState(
      projects: state.projects,
      currentId: id,
      currentChatId: project.generalChat.id,
    );
    ref.read(tabProvider.notifier).select(AppTab.chat);
  }

  void selectChat(int chatId) {
    state = ProjectsState(
      projects: state.projects,
      currentId: state.currentId,
      currentChatId: chatId,
    );
    ref.read(tabProvider.notifier).select(AppTab.chat);
    if (state.current.generalChat.id == chatId) _deliverStepUp();
  }

  /// A topic chat asked for a bigger step: General shows the step-up card
  /// once, then the flag goes back to 0.
  Future<void> _deliverStepUp() async {
    final id = state.current.id;
    final rows = await _db.habits();
    final habit = rows.where((h) => h['id'] == id).firstOrNull;
    if (habit == null || habit['pending_step_up'] != 1) return;
    await _db.updateHabit(id, {'pending_step_up': 0});
    await ref.read(chatProvider.notifier).openStepUp();
  }

  void openGeneral() => selectChat(state.current.generalChat.id);

  /// Deletes every chat of every habit. Topic chats disappear and General
  /// stays, empty.
  Future<void> deleteAllChats() async {
    for (final project in state.projects) {
      for (final chat in project.chats) {
        await _db.deleteChat(chat.id);
      }
    }
    final current = state.currentId;
    state = ProjectsState(
      projects: [
        for (final p in state.projects)
          Project(id: p.id, name: p.name, chats: [p.generalChat]),
      ],
      currentId: current,
      currentChatId: state.current.generalChat.id,
    );
    ref.invalidate(topicChatsProvider);
    await ref.read(chatProvider.notifier).clearMessages();
  }

  /// Opens the chat with this name, or creates it. Returns false if the
  /// name is empty.
  Future<bool> startChat(String name) async {
    final title = name.trim();
    if (title.isEmpty) return false;
    final current = state.current;
    final existing = current.chats.where(
      (c) => c.title.toLowerCase() == title.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      selectChat(existing.first.id);
      return true;
    }
    final id = await _db.createChat(current.id, 'topic', title);
    final chat = ChatInfo(id: id, title: title);
    state = ProjectsState(
      projects: [
        for (final p in state.projects)
          p.id == current.id
              ? Project(id: p.id, name: p.name, chats: [...p.chats, chat])
              : p,
      ],
      currentId: current.id,
      currentChatId: chat.id,
    );
    ref.read(tabProvider.notifier).select(AppTab.chat);
    return true;
  }
}

final projectsProvider = NotifierProvider<ProjectsController, ProjectsState>(
  ProjectsController.new,
);

/// Messages of the topic chats, by chat row id. A topic chat can only
/// suggest: a bigger step sets `habit.pending_step_up`, and General shows the
/// step-up card the next time it opens, where the rules engine and the user's
/// yes decide.
class TopicChats extends Notifier<Map<int, List<ChatMessage>>> {
  @override
  Map<int, List<ChatMessage>> build() {
    ref.watch(startupProvider);
    return {};
  }

  AppDatabase get _db => ref.read(databaseProvider);

  /// Loads the saved messages when a topic chat opens.
  Future<void> load(int chatId) async {
    final rows = await _db.messagesOf(chatId);
    state = {
      ...state,
      chatId: [for (final r in rows) messageFromRow(r)],
    };
  }

  /// Saves one message, then shows it.
  Future<int> _save(
    int chatId,
    String role, {
    String text = '',
    String? textKey,
    ChatCard? card,
  }) async {
    final kind = card != null ? 'card' : (textKey != null ? 'fixed' : 'text');
    final cardData = card == null ? null : jsonEncode(card.toJson());
    final id = await _db.addMessage(
      chatId,
      role,
      kind: kind,
      text: text,
      textKey: textKey,
      cardType: card?.type,
      cardData: cardData,
    );
    final message = messageFromRow({
      'id': id,
      'role': role,
      'kind': kind,
      'text': text,
      'text_key': textKey,
      'card_type': card?.type,
      'card_data': cardData,
      'card_answer': null,
      'status': 'sent',
    });
    state = {
      ...state,
      chatId: [...(state[chatId] ?? const []), message],
    };
    return id;
  }

  Future<void> send(int chatId, String topic, String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    final id = await _save(chatId, 'user', text: text);
    await _ask(chatId, topic, id);
  }

  /// "Try again" on a failed message: it is sent again, not copied.
  Future<void> retry(int chatId, String topic, int messageId) async {
    await _mark(chatId, messageId, failed: false);
    await _ask(chatId, topic, messageId);
  }

  Future<void> _mark(int chatId, int messageId, {required bool failed}) async {
    await _db.setStatus(messageId, failed ? 'failed' : 'sent');
    state = {
      ...state,
      chatId: [
        for (final m in state[chatId] ?? const <ChatMessage>[])
          m.id == messageId ? m.withFailed(failed) : m,
      ],
    };
  }

  Future<void> _ask(int chatId, String topic, int userId) async {
    final chat = ref.read(chatProvider);
    final language = ref.read(languageProvider);
    try {
      // The same last-10 rule as the General chat, so a long topic chat never
      // goes over the gateway limit.
      final reply = await askCoach(
        ref.read(llmProvider),
        language: language == AppLanguage.si ? 'Sinhala' : 'English',
        summary:
            'Goal: ${chat.goal ?? ''}. Level: ${chat.level ?? ''}. '
            '${chat.healthLock ? 'Keep very gentle. ' : ''}'
            'This is the "$topic" topic chat.',
        rows: await _db.recentTextMessages(chatId),
      );
      if (isBlocked(reply.text)) {
        await _save(chatId, 'assistant', textKey: 'chat.safe_fallback');
        return;
      }
      await _save(chatId, 'assistant', text: reply.text);
      if (reply.wantsBigger) {
        await _db.updateHabit(ref.read(projectsProvider).current.id, {
          'pending_step_up': 1,
        });
        await _save(chatId, 'assistant', card: const InfoCardData());
      }
    } catch (e) {
      await _mark(chatId, userId, failed: true);
      if (e is AiException && e.code == 'rate_limited') {
        await _save(chatId, 'assistant', textKey: 'chat.rate_limited');
      }
    }
  }

  /// "Open General": go there. A waiting suggestion shows the step-up card.
  void openGeneral() => ref.read(projectsProvider.notifier).openGeneral();
}

final topicChatsProvider =
    NotifierProvider<TopicChats, Map<int, List<ChatMessage>>>(TopicChats.new);
