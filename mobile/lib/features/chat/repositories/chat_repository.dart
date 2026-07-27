import '../models/chat_model.dart';
import '../services/ai_chat_service.dart';
import '../../../core/cache/local_cache.dart';

/// Abstract repository for chat messages.
abstract class ChatRepository {
  /// Get chat history for the current user.
  Future<List<ChatModel>> getHistory();

  /// Send a user message and get the AI response back.
  ///
  /// Returns both the saved user message and the generated assistant message.
  /// In local mode, uses the AIChatService.
  /// In API mode, calls POST /chat which returns both messages.
  Future<({ChatModel userMessage, ChatModel assistantMessage})> sendMessage(
      String content);
}

/// In-memory implementation for offline / development.
///
/// Uses [AIChatService] (passed via constructor) to generate responses.
class InMemoryChatRepository implements ChatRepository {
  final List<ChatModel> _messages = [];
  final dynamic _aiService; // AIChatService

  InMemoryChatRepository(this._aiService);

  @override
  Future<List<ChatModel>> getHistory() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_messages);
  }

  @override
  Future<({ChatModel userMessage, ChatModel assistantMessage})> sendMessage(
      String content) async {
    final userMsg = ChatModel.user(content: content);
    _messages.add(userMsg);

    // Generate AI response using the local service
    final aiContent = await _aiService.generateResponse(content);
    final aiMsg = ChatModel.assistant(content: aiContent);
    _messages.add(aiMsg);

    return (userMessage: userMsg, assistantMessage: aiMsg);
  }
}

/// API-backed repository.
///
/// Connects to the Haven backend:
/// - POST /chat → send message, get AI response
/// - GET  /chat → history
class ApiChatRepository implements ChatRepository {
  final dynamic _dio; // Dio instance

  ApiChatRepository(this._dio);

  @override
  Future<List<ChatModel>> getHistory() async {
    final response = await _dio.get('/chat');
    final List data = response.data as List;
    return data.map((j) => ChatModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<({ChatModel userMessage, ChatModel assistantMessage})> sendMessage(
      String content) async {
    final response = await _dio.post('/chat', data: {
      'content': content,
    });

    final data = response.data as Map<String, dynamic>;
    final userMsg = ChatModel.fromJson(
      data['user_message'] as Map<String, dynamic>,
    );
    final aiMsg = ChatModel.fromJson(
      data['assistant_message'] as Map<String, dynamic>,
    );

    return (userMessage: userMsg, assistantMessage: aiMsg);
  }
}

/// Caching decorator for chat repository.
///
/// Wraps [ApiChatRepository] with offline resilience:
/// - On read success: caches history to [LocalCache].
/// - On read failure: returns cached history.
/// - On send failure: falls back to local [AIChatService] (mock AI)
///   so the user can still talk, with a note that it's offline mode.
class CachingChatRepository implements ChatRepository {
  final ChatRepository _api;
  final InMemoryChatRepository _local;

  static const _keyHistory = 'chat_history';

  CachingChatRepository(this._api) : _local = InMemoryChatRepository(AIChatService());

  @override
  Future<List<ChatModel>> getHistory() async {
    try {
      final history = await _api.getHistory();
      // Cache the result
      await LocalCache.saveList(
        _keyHistory,
        history.map((m) => m.toJson()).toList(),
      );
      // Also feed into local for continuity
      _local._messages.clear();
      _local._messages.addAll(history);
      return history;
    } catch (_) {
      // Offline — return cached data
      final cached = LocalCache.getList(_keyHistory);
      if (cached != null) {
        final messages = cached.map((j) => ChatModel.fromJson(j)).toList();
        _local._messages.clear();
        _local._messages.addAll(messages);
        return messages;
      }
      // Fall back to any local session messages
      return _local.getHistory();
    }
  }

  @override
  Future<({ChatModel userMessage, ChatModel assistantMessage})> sendMessage(
      String content) async {
    try {
      final result = await _api.sendMessage(content);
      // Append to local for continuity
      _local._messages.add(result.userMessage);
      _local._messages.add(result.assistantMessage);
      // Update cache
      final cached = LocalCache.getList(_keyHistory) ?? [];
      cached.add(result.userMessage.toJson());
      cached.add(result.assistantMessage.toJson());
      await LocalCache.saveList(_keyHistory, cached);
      return result;
    } catch (_) {
      // Offline — use local AI service (mock)
      final result = await _local.sendMessage(content);
      // Prepend an offline note to the AI response
      final offlineNote = ChatModel.assistant(
        content:
            '（离线模式）我现在用的是本地模拟回复，连接恢复后会切换到更完整的对话。\n\n${result.assistantMessage.content}',
      );
      // Replace the assistant message with the annotated version
      _local._messages.removeLast();
      _local._messages.add(offlineNote);
      // Update cache
      final cached = LocalCache.getList(_keyHistory) ?? [];
      cached.add(result.userMessage.toJson());
      cached.add(offlineNote.toJson());
      await LocalCache.saveList(_keyHistory, cached);
      return (userMessage: result.userMessage, assistantMessage: offlineNote);
    }
  }
}
