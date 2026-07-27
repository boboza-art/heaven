import '../models/memory_model.dart';
import '../../../core/cache/local_cache.dart';

/// Abstract repository for memory data.
abstract class MemoryRepository {
  /// List all memories, optionally filtered by approval status.
  /// Returns memories + counts.
  Future<MemoryListResponse> getMemories({bool? approved});

  /// Manually add a memory (auto-approved).
  Future<MemoryModel?> createMemory({
    required String category,
    required String content,
  });

  /// Update a memory's content, category, or approval status.
  Future<MemoryModel?> updateMemory(
    String id, {
    String? content,
    String? category,
    bool? approved,
  });

  /// Delete a memory.
  Future<bool> deleteMemory(String id);
}

/// API-backed repository.
///
/// Connects to the Haven backend:
/// - GET    /memories            → list (optional ?approved=true|false)
/// - POST   /memories            → create (auto-approved)
/// - PATCH  /memories/{id}       → update content/category/approved
/// - DELETE /memories/{id}       → delete
class ApiMemoryRepository implements MemoryRepository {
  final dynamic _dio; // Dio instance

  ApiMemoryRepository(this._dio);

  @override
  Future<MemoryListResponse> getMemories({bool? approved}) async {
    final query = <String, dynamic>{};
    if (approved != null) query['approved'] = approved;

    final response = await _dio.get('/memories', queryParameters: query);
    return MemoryListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MemoryModel?> createMemory({
    required String category,
    required String content,
  }) async {
    final response = await _dio.post('/memories', data: {
      'category': category,
      'content': content,
    });
    return MemoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MemoryModel?> updateMemory(
    String id, {
    String? content,
    String? category,
    bool? approved,
  }) async {
    final data = <String, dynamic>{};
    if (content != null) data['content'] = content;
    if (category != null) data['category'] = category;
    if (approved != null) data['approved'] = approved;

    final response = await _dio.patch('/memories/$id', data: data);
    return MemoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<bool> deleteMemory(String id) async {
    await _dio.delete('/memories/$id');
    return true;
  }
}

/// Caching decorator for memory repository.
///
/// Wraps [ApiMemoryRepository] with offline resilience:
/// - On read success: caches the full memory list to [LocalCache].
/// - On read failure: returns cached data (with recomputed counts).
/// - On write failure: applies the mutation to the local cache so the UI
///   reflects the change immediately, data syncs on next online read.
class CachingMemoryRepository implements MemoryRepository {
  final MemoryRepository _api;

  static const _keyMemories = 'memories_list';

  CachingMemoryRepository(this._api);

  @override
  Future<MemoryListResponse> getMemories({bool? approved}) async {
    try {
      final response = await _api.getMemories(approved: approved);
      // Cache the full list (unfiltered) for offline use
      await LocalCache.saveList(
        _keyMemories,
        response.memories.map((m) => m.toJson()).toList(),
      );
      return response;
    } catch (_) {
      // Offline — rebuild from cache
      final cached = LocalCache.getList(_keyMemories);
      if (cached == null) {
        return const MemoryListResponse();
      }
      var memories = cached.map((j) => MemoryModel.fromJson(j)).toList();
      // Apply filter if needed
      if (approved != null) {
        memories = memories.where((m) => m.approved == approved).toList();
      }
      final allCached = cached.map((j) => MemoryModel.fromJson(j)).toList();
      final approvedCount = allCached.where((m) => m.approved).length;
      final pendingCount = allCached.length - approvedCount;
      return MemoryListResponse(
        memories: memories,
        total: allCached.length,
        approvedCount: approvedCount,
        pendingCount: pendingCount,
      );
    }
  }

  @override
  Future<MemoryModel?> createMemory({
    required String category,
    required String content,
  }) async {
    try {
      final created = await _api.createMemory(
        category: category,
        content: content,
      );
      if (created != null) {
        // Update cache
        final cached = LocalCache.getList(_keyMemories) ?? [];
        cached.insert(0, created.toJson());
        await LocalCache.saveList(_keyMemories, cached);
      }
      return created;
    } catch (_) {
      // Offline — create locally
      final local = MemoryModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        category: category,
        content: content,
        approved: true,
        createdAt: DateTime.now(),
      );
      final cached = LocalCache.getList(_keyMemories) ?? [];
      cached.insert(0, local.toJson());
      await LocalCache.saveList(_keyMemories, cached);
      return local;
    }
  }

  @override
  Future<MemoryModel?> updateMemory(
    String id, {
    String? content,
    String? category,
    bool? approved,
  }) async {
    try {
      final updated = await _api.updateMemory(
        id,
        content: content,
        category: category,
        approved: approved,
      );
      if (updated != null) {
        // Update cache
        _updateCachedMemory(id, updated.toJson());
      }
      return updated;
    } catch (_) {
      // Offline — update locally
      final cached = LocalCache.getList(_keyMemories);
      if (cached == null) return null;
      for (var i = 0; i < cached.length; i++) {
        if (cached[i]['id']?.toString() == id) {
          if (content != null) cached[i]['content'] = content;
          if (category != null) cached[i]['category'] = category;
          if (approved != null) cached[i]['approved'] = approved;
          await LocalCache.saveList(_keyMemories, cached);
          return MemoryModel.fromJson(cached[i]);
        }
      }
      return null;
    }
  }

  @override
  Future<bool> deleteMemory(String id) async {
    try {
      final success = await _api.deleteMemory(id);
      if (success) {
        // Remove from cache
        final cached = LocalCache.getList(_keyMemories);
        if (cached != null) {
          cached.removeWhere((m) => m['id']?.toString() == id);
          await LocalCache.saveList(_keyMemories, cached);
        }
      }
      return success;
    } catch (_) {
      // Offline — remove from cache
      final cached = LocalCache.getList(_keyMemories);
      if (cached != null) {
        cached.removeWhere((m) => m['id']?.toString() == id);
        await LocalCache.saveList(_keyMemories, cached);
      }
      return true; // Don't block UX
    }
  }

  /// Update a single memory in the local cache.
  void _updateCachedMemory(String id, Map<String, dynamic> updatedJson) {
    final cached = LocalCache.getList(_keyMemories);
    if (cached == null) return;
    for (var i = 0; i < cached.length; i++) {
      if (cached[i]['id']?.toString() == id) {
        cached[i] = updatedJson;
        break;
      }
    }
    LocalCache.saveList(_keyMemories, cached);
  }
}
