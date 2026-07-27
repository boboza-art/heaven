import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';
import '../../../core/network/dio_provider.dart';
import 'chat_state.dart';

/// Repository provider — uses caching decorator with offline fallback.
///
/// Wraps [ApiChatRepository] in [CachingChatRepository]:
/// - Online: calls backend, caches history.
/// - Offline: falls back to local [AIChatService] (mock) with an offline note.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CachingChatRepository(ApiChatRepository(dio));
});

/// Chat state notifier.
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;

  ChatNotifier(this._repository) : super(ChatState.initial);

  /// Show welcome message if it's first visit.
  void showWelcome() {
    if (state.hasSeenWelcome) return;

    final welcomeMsg = ChatModel.assistant(
      content: '你好，我在这里。今天想聊些什么？',
    );

    state = state.copyWith(
      messages: [welcomeMsg],
      hasSeenWelcome: true,
    );
  }

  /// Send a user message and get AI response.
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message immediately for responsive UI.
    final userMsg = ChatModel.user(content: content.trim());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isSending: true,
      clearError: true,
    );

    try {
      // The repository sends the message and returns both
      // the saved user message and the AI assistant message.
      final result = await _repository.sendMessage(content.trim());

      // Replace the optimistic user message with the backend-saved one,
      // and append the AI response.
      state = state.copyWith(
        messages: [
          ...state.messages.sublist(0, state.messages.length - 1),
          result.userMessage,
          result.assistantMessage,
        ],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: '出错了，请再试一次',
      );
    }
  }

  /// Load chat history.
  Future<void> loadHistory() async {
    state = state.copyWith(isLoadingHistory: true);
    try {
      final messages = await _repository.getHistory();
      state = state.copyWith(
        messages: messages,
        isLoadingHistory: false,
        hasSeenWelcome: messages.isNotEmpty,
      );
    } catch (_) {
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repository);
});
