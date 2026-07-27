/// Chat message model.
///
/// Represents a single message in the AI conversation.
class ChatModel {
  /// Unique message id.
  final String id;

  /// Message role: 'user' or 'assistant'.
  final String role;

  /// Message content.
  final String content;

  /// When the message was created.
  final DateTime createdAt;

  /// Whether the message is still being generated (streaming).
  final bool isStreaming;

  const ChatModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isStreaming = false,
  });

  /// Create a user message.
  factory ChatModel.user({required String content}) {
    return ChatModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );
  }

  /// Create an assistant message.
  factory ChatModel.assistant({required String content}) {
    return ChatModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: 'assistant',
      content: content,
      createdAt: DateTime.now(),
    );
  }

  /// Create a streaming placeholder for assistant.
  factory ChatModel.streaming() {
    return ChatModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
      isStreaming: true,
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  ChatModel copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? createdAt,
    bool? isStreaming,
  }) {
    return ChatModel(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
