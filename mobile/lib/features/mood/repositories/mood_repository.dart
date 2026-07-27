import '../models/mood_model.dart';
import '../../../core/cache/local_cache.dart';

/// Abstract repository for mood data.
abstract class MoodRepository {
  /// Save a mood entry.
  /// Returns the saved mood (with backend-assigned id) on success.
  Future<MoodModel?> saveMood(MoodModel mood);

  /// Get mood history for the current user.
  Future<List<MoodModel>> getMoodHistory();

  /// Get today's mood, if any.
  Future<MoodModel?> getTodayMood();

  /// Get mood trend (average, count, distribution).
  Future<MoodTrend?> getMoodTrend();
}

/// Trend data returned by the backend.
class MoodTrend {
  final double? average;
  final int count;

  const MoodTrend({this.average, this.count});
}

/// In-memory implementation for offline / development.
class InMemoryMoodRepository implements MoodRepository {
  final List<MoodModel> _moods = [];

  @override
  Future<MoodModel?> saveMood(MoodModel mood) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _moods.add(mood);
    return mood;
  }

  @override
  Future<List<MoodModel>> getMoodHistory() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_moods);
  }

  @override
  Future<MoodModel?> getTodayMood() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final mood in _moods.reversed) {
      final moodDate = DateTime(
        mood.createdAt.year,
        mood.createdAt.month,
        mood.createdAt.day,
      );
      if (moodDate == today) return mood;
    }
    return null;
  }

  @override
  Future<MoodTrend?> getMoodTrend() async {
    if (_moods.isEmpty) return null;
    final avg = _moods.map((m) => m.moodLevel).reduce((a, b) => a + b) /
        _moods.length;
    return MoodTrend(average: avg, count: _moods.length);
  }
}

/// API-backed repository.
///
/// Connects to the Haven backend:
/// - POST /mood          → save mood
/// - GET  /mood          → history
/// - GET  /mood/trend    → trend
///
/// [getTodayMood] filters from the history since the backend
/// doesn't have a dedicated /mood/today endpoint.
class ApiMoodRepository implements MoodRepository {
  final dynamic _dio; // Dio instance

  ApiMoodRepository(this._dio);

  @override
  Future<MoodModel?> saveMood(MoodModel mood) async {
    final response = await _dio.post('/mood', data: {
      'mood_level': mood.moodLevel,
      'note': mood.note,
    });
    return MoodModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<MoodModel>> getMoodHistory() async {
    final response = await _dio.get('/mood');
    final List data = response.data as List;
    return data.map((j) => MoodModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<MoodModel?> getTodayMood() async {
    final history = await getMoodHistory();
    if (history.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final mood in history.reversed) {
      final moodDate = DateTime(
        mood.createdAt.year,
        mood.createdAt.month,
        mood.createdAt.day,
      );
      if (moodDate == today) return mood;
    }
    return null;
  }

  @override
  Future<MoodTrend?> getMoodTrend() async {
    final response = await _dio.get('/mood/trend');
    final data = response.data as Map<String, dynamic>;
    return MoodTrend(
      average: (data['average'] as num?)?.toDouble(),
      count: data['count'] as int? ?? 0,
    );
  }
}

/// Caching decorator for mood repository.
///
/// Wraps [ApiMoodRepository] with offline resilience:
/// - On read success: caches results to [LocalCache].
/// - On read failure: returns cached data (or empty list).
/// - On write failure: saves to a local pending list so data isn't lost.
class CachingMoodRepository implements MoodRepository {
  final MoodRepository _api;
  final InMemoryMoodRepository _local = InMemoryMoodRepository();

  static const _keyHistory = 'mood_history';
  static const _keyToday = 'mood_today';

  CachingMoodRepository(this._api);

  @override
  Future<MoodModel?> saveMood(MoodModel mood) async {
    try {
      final saved = await _api.saveMood(mood);
      if (saved != null) {
        // Update cache: prepend to history
        final cached = LocalCache.getList(_keyHistory) ?? [];
        cached.insert(0, saved.toJson());
        await LocalCache.saveList(_keyHistory, cached);
        await LocalCache.saveJson(_keyToday, saved.toJson());
      }
      return saved;
    } catch (_) {
      // Offline — save locally so it's not lost
      await _local.saveMood(mood);
      await LocalCache.saveJson(_keyToday, mood.toJson());
      return mood;
    }
  }

  @override
  Future<List<MoodModel>> getMoodHistory() async {
    try {
      final history = await _api.getMoodHistory();
      // Cache the result
      await LocalCache.saveList(
        _keyHistory,
        history.map((m) => m.toJson()).toList(),
      );
      return history;
    } catch (_) {
      // Offline — return cached data
      final cached = LocalCache.getList(_keyHistory);
      if (cached != null) {
        return cached.map((j) => MoodModel.fromJson(j)).toList();
      }
      // Also check local pending saves
      final localHistory = await _local.getMoodHistory();
      if (localHistory.isNotEmpty) return localHistory;
      return [];
    }
  }

  @override
  Future<MoodModel?> getTodayMood() async {
    try {
      final mood = await _api.getTodayMood();
      if (mood != null) {
        await LocalCache.saveJson(_keyToday, mood.toJson());
      }
      return mood;
    } catch (_) {
      // Offline — check cache, then local
      final cached = LocalCache.getJson(_keyToday);
      if (cached != null) {
        final mood = MoodModel.fromJson(cached);
        // Verify it's actually today
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final moodDate = DateTime(
          mood.createdAt.year,
          mood.createdAt.month,
          mood.createdAt.day,
        );
        if (moodDate == today) return mood;
      }
      return _local.getTodayMood();
    }
  }

  @override
  Future<MoodTrend?> getMoodTrend() async {
    try {
      return await _api.getMoodTrend();
    } catch (_) {
      // Offline — compute from cached history
      final cached = LocalCache.getList(_keyHistory);
      if (cached == null || cached.isEmpty) return null;
      final moods = cached.map((j) => MoodModel.fromJson(j)).toList();
      final avg = moods.map((m) => m.moodLevel).reduce((a, b) => a + b) /
          moods.length;
      return MoodTrend(average: avg, count: moods.length);
    }
  }
}
