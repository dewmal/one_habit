import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/llm_client.dart';
import '../chat/chat_controller.dart';
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

  Project get current => projects.firstWhere((p) => p.id == currentId);

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
  }

  void openGeneral() => selectChat(state.current.generalChat.id);

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

/// One message in a topic chat.
class TopicMessage {
  const TopicMessage({
    required this.fromUser,
    required this.text,
    this.suggestion = false,
  });

  final bool fromUser;
  final String text;

  /// True when this coach message asked General for a plan change.
  final bool suggestion;
}

/// Messages of the topic chats, by chat id. A topic chat can only suggest:
/// a suggestion is kept in [pendingSuggestion] until General is opened, where
/// the rules engine and the user's yes decide.
class TopicChats extends Notifier<Map<int, List<TopicMessage>>> {
  @override
  Map<int, List<TopicMessage>> build() => {};

  bool pendingSuggestion = false;

  void _add(int chatId, TopicMessage m) => state = {
    ...state,
    chatId: [...(state[chatId] ?? const []), m],
  };

  Future<void> send(int chatId, String topic, String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    final history = [
      for (final m in state[chatId] ?? const <TopicMessage>[])
        ChatTurn(role: m.fromUser ? 'user' : 'assistant', content: m.text),
      ChatTurn(role: 'user', content: text),
    ];
    _add(chatId, TopicMessage(fromUser: true, text: text));
    final chat = ref.read(chatProvider);
    final language = ref.read(languageProvider);
    try {
      final reply = await ref
          .read(llmProvider)
          .chatReply(
            language: language == AppLanguage.si ? 'Sinhala' : 'English',
            summary:
                'Goal: ${chat.goal ?? ''}. Level: ${chat.level ?? ''}. '
                'This is the "$topic" topic chat.',
            history: history,
          );
      if (isBlocked(reply.text)) return;
      _add(chatId, TopicMessage(fromUser: false, text: reply.text));
      if (reply.wantsBigger) {
        pendingSuggestion = true;
        _add(
          chatId,
          const TopicMessage(fromUser: false, text: '', suggestion: true),
        );
      }
    } catch (_) {
      _add(
        chatId,
        TopicMessage(fromUser: false, text: tr('chat.no_connection', language)),
      );
    }
  }

  /// "Open General": go there and hand over a waiting suggestion.
  void openGeneral() {
    ref.read(projectsProvider.notifier).openGeneral();
    if (pendingSuggestion) {
      pendingSuggestion = false;
      ref.read(chatProvider.notifier).openStepUp();
    }
  }
}

final topicChatsProvider =
    NotifierProvider<TopicChats, Map<int, List<TopicMessage>>>(TopicChats.new);
