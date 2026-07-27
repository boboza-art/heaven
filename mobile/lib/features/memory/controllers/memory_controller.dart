import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/memory_model.dart';
import '../repositories/memory_repository.dart';
import '../../../core/network/dio_provider.dart';
import 'memory_state.dart';

/// Repository provider — uses caching decorator with offline resilience.
///
/// Wraps [ApiMemoryRepository] in [CachingMemoryRepository]:
/// - Online: calls backend, caches memory list.
/// - Offline: returns cached memories, mutations applied locally.
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CachingMemoryRepository(ApiMemoryRepository(dio));
});

/// Memory state notifier.
///
/// Handles all business logic for memory management:
/// loading, creating, updating (approve/edit), and deleting.
class MemoryNotifier extends StateNotifier<MemoryState> {
  final MemoryRepository _repository;

  MemoryNotifier(this._repository) : super(MemoryState.initial);

  /// Load all memories from the backend.
  Future<void> loadMemories() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _repository.getMemories();
      state = state.copyWith(
        memories: response.memories,
        approvedCount: response.approvedCount,
        pendingCount: response.pendingCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '加载失败，请下拉刷新重试',
      );
    }
  }

  /// Approve a pending memory.
  Future<void> approveMemory(String id) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final updated = await _repository.updateMemory(id, approved: true);
      if (updated != null) {
        final newMemories = state.memories.map((m) {
          return m.id == id ? updated : m;
        }).toList();
        state = state.copyWith(
          memories: newMemories,
          approvedCount: state.approvedCount + 1,
          pendingCount: state.pendingCount - 1,
          isProcessing: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: '操作失败，请再试一次',
      );
    }
  }

  /// Edit a memory's content and/or category.
  Future<bool> editMemory(
    String id, {
    String? content,
    String? category,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final updated = await _repository.updateMemory(
        id,
        content: content,
        category: category,
      );
      if (updated != null) {
        final newMemories = state.memories.map((m) {
          return m.id == id ? updated : m;
        }).toList();
        state = state.copyWith(
          memories: newMemories,
          isProcessing: false,
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: '保存失败，请再试一次',
      );
      return false;
    }
  }

  /// Delete a memory.
  Future<bool> deleteMemory(String id) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final success = await _repository.deleteMemory(id);
      if (success) {
        // Find the memory before removing to check its approval status
        final target = state.memories.where((m) => m.id == id).toList();
        final wasApproved = target.isNotEmpty && target.first.approved;

        final newMemories =
            state.memories.where((m) => m.id != id).toList();
        state = state.copyWith(
          memories: newMemories,
          approvedCount:
              wasApproved ? state.approvedCount - 1 : state.approvedCount,
          pendingCount:
              !wasApproved ? state.pendingCount - 1 : state.pendingCount,
          isProcessing: false,
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: '删除失败，请再试一次',
      );
      return false;
    }
  }

  /// Manually add a memory (auto-approved).
  Future<bool> addMemory({
    required String category,
    required String content,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final created = await _repository.createMemory(
        category: category,
        content: content,
      );
      if (created != null) {
        final newMemories = [created, ...state.memories];
        state = state.copyWith(
          memories: newMemories,
          approvedCount: state.approvedCount + 1,
          isProcessing: false,
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: '添加失败，请再试一次',
      );
      return false;
    }
  }

  /// Clear error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// The main memory controller provider.
final memoryControllerProvider =
    StateNotifierProvider<MemoryNotifier, MemoryState>((ref) {
  final repository = ref.watch(memoryRepositoryProvider);
  return MemoryNotifier(repository);
});
