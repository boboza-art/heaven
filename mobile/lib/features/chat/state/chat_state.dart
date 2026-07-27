import '../models/chat_model.dart';

/// UI state for the chat feature.
class ChatState {
  final List<ChatModel> messages;
  final bool isSending;
  final bool isLoadingHistory;
  final String? errorMessage;
  final bool hasSeenWelcome;

  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.isLoadingHistory = false,
    this.errorMessage,
    this.hasSeenWelcome = false,
  });

  static const ChatState initial = ChatState();

  /// Whether the chat is still empty (no user messages yet).
  bool get isEmpty => messages.where((m) => m.isUser).isEmpty;

  ChatState copyWith({
    List<ChatModel>? messages,
    bool? isSending,
    bool? isLoadingHistory,
    String? errorMessage,
    bool? hasSeenWelcome,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasSeenWelcome: hasSeenWelcome ?? this.hasSeenWelcome,
    );
  }
}
