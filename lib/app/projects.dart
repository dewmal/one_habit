import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/llm_client.dart';
import '../chat/chat_controller.dart';
import '../i18n/language.dart';
import 'rules.dart';
import 'tabs.dart';

/// One chat inside a habit. The General chat is pinned and the only one
/// that can change the plan.
class ChatInfo {
  const ChatInfo({required this.id, required this.title, this.general = false});

  final String id;
  final String title;
  final bool general;
}

/// One habit (project). The first layout had only one.
class Project {
  const Project({required this.id, required this.name, required this.chats});

  final String id;
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
  final String currentId;
  final String currentChatId;

  Project get current => projects.firstWhere((p) => p.id == currentId);

  ChatInfo get currentChat => current.chats.firstWhere(
    (c) => c.id == currentChatId,
    orElse: () => current.generalChat,
  );
}

/// Topics offered on the New chat screen (plugin topics for now).
const newChatTopics = ['Exercise', 'Diet', 'Health issues'];

Project _project(String id, String name, {List<String> topics = const []}) =>
    Project(
      id: id,
      name: name,
      chats: [
        ChatInfo(id: '$id-general', title: 'General', general: true),
        for (final t in topics) ChatInfo(id: '$id-$t', title: t),
      ],
    );

/// Sample habits until projects are stored in the database. Only the first
/// one has real data behind it.
final _sampleProjects = [
  _project('fitness', 'Improve my fitness', topics: newChatTopics),
  _project('read', 'Read more'),
  _project('water', 'Drink water'),
  _project('sleep', 'Sleep earlier'),
  _project('study', 'Study daily'),
];

class ProjectsController extends Notifier<ProjectsState> {
  @override
  ProjectsState build() => ProjectsState(
    projects: _sampleProjects,
    currentId: _sampleProjects.first.id,
    currentChatId: _sampleProjects.first.generalChat.id,
  );

  /// Tapping a habit makes it the current project, on its General chat.
  void selectProject(String id) {
    final project = state.projects.firstWhere((p) => p.id == id);
    state = ProjectsState(
      projects: state.projects,
      currentId: id,
      currentChatId: project.generalChat.id,
    );
    ref.read(tabProvider.notifier).select(AppTab.chat);
  }

  void selectChat(String chatId) {
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
  bool startChat(String name) {
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
    final chat = ChatInfo(id: '${current.id}-$title', title: title);
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
class TopicChats extends Notifier<Map<String, List<TopicMessage>>> {
  @override
  Map<String, List<TopicMessage>> build() => {};

  bool pendingSuggestion = false;

  void _add(String chatId, TopicMessage m) => state = {
    ...state,
    chatId: [...(state[chatId] ?? const []), m],
  };

  Future<void> send(String chatId, String topic, String raw) async {
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
    NotifierProvider<TopicChats, Map<String, List<TopicMessage>>>(
      TopicChats.new,
    );
