import '../models/exercise_model.dart';
import '../../../core/cache/local_cache.dart';

/// Abstract repository for exercise data.
abstract class ExerciseRepository {
  /// Get all available exercises.
  Future<List<ExerciseModel>> getExercises();

  /// Mark an exercise as completed.
  /// Returns true on success.
  Future<bool> completeExercise(String exerciseId, {int? durationSeconds});
}

/// In-memory implementation for offline / development.
class InMemoryExerciseRepository implements ExerciseRepository {
  final List<ExerciseModel> _exercises = ExerciseModel.defaults;
  final Set<String> _completedIds = {};

  @override
  Future<List<ExerciseModel>> getExercises() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_exercises);
  }

  @override
  Future<bool> completeExercise(String exerciseId,
      {int? durationSeconds}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _completedIds.add(exerciseId);
    return true;
  }
}

/// API-backed repository.
///
/// Connects to the Haven backend:
/// - GET  /exercises           → list all exercises
/// - GET  /exercises/{id}       → exercise detail
/// - POST /exercises/{id}/complete → mark as completed
class ApiExerciseRepository implements ExerciseRepository {
  final dynamic _dio; // Dio instance

  ApiExerciseRepository(this._dio);

  @override
  Future<List<ExerciseModel>> getExercises() async {
    try {
      final response = await _dio.get('/exercises');
      final List data = response.data as List;
      return data
          .map((j) => ExerciseModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback to local defaults if backend is unavailable
      return ExerciseModel.defaults;
    }
  }

  @override
  Future<bool> completeExercise(String exerciseId,
      {int? durationSeconds}) async {
    try {
      await _dio.post('/exercises/$exerciseId/complete', data: {
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
      });
      return true;
    } catch (_) {
      // Non-critical — silently fail
      return false;
    }
  }
}

/// Caching decorator for exercise repository.
///
/// Wraps [ApiExerciseRepository] with offline resilience:
/// - On read success: caches exercise list to [LocalCache].
/// - On read failure: returns cached data, or built-in defaults.
/// - On complete failure: caches completion locally (non-blocking).
class CachingExerciseRepository implements ExerciseRepository {
  final ExerciseRepository _api;
  final Set<String> _completedIds = {};

  static const _keyExercises = 'exercises_list';
  static const _keyCompleted = 'exercises_completed';

  CachingExerciseRepository(this._api);

  @override
  Future<List<ExerciseModel>> getExercises() async {
    try {
      final exercises = await _api.getExercises();
      // Cache the result
      await LocalCache.saveList(
        _keyExercises,
        exercises.map((e) => e.toJson()).toList(),
      );
      return exercises;
    } catch (_) {
      // Offline — return cached data
      final cached = LocalCache.getList(_keyExercises);
      if (cached != null && cached.isNotEmpty) {
        return cached.map((j) => ExerciseModel.fromJson(j)).toList();
      }
      // Ultimate fallback — built-in defaults
      return ExerciseModel.defaults;
    }
  }

  @override
  Future<bool> completeExercise(String exerciseId,
      {int? durationSeconds}) async {
    try {
      final success = await _api.completeExercise(
        exerciseId,
        durationSeconds: durationSeconds,
      );
      // Track completion locally
      _completedIds.add(exerciseId);
      return success;
    } catch (_) {
      // Offline — track locally, will sync later
      _completedIds.add(exerciseId);
      return true; // Don't block the user's UX
    }
  }
}
