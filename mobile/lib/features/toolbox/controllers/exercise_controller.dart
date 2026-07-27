import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise_model.dart';
import '../repositories/exercise_repository.dart';
import '../../../core/network/dio_provider.dart';
import 'exercise_state.dart';

/// Repository provider — uses caching decorator with offline resilience.
///
/// Wraps [ApiExerciseRepository] in [CachingExerciseRepository]:
/// - Online: calls backend, caches exercise list.
/// - Offline: returns cached exercises, or built-in defaults.
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CachingExerciseRepository(ApiExerciseRepository(dio));
});

/// Exercise state notifier.
class ExerciseNotifier extends StateNotifier<ExerciseState> {
  final ExerciseRepository _repository;

  ExerciseNotifier(this._repository) : super(ExerciseState.initial);

  /// Load all available exercises.
  Future<void> loadExercises() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final exercises = await _repository.getExercises();
      state = state.copyWith(exercises: exercises, isLoading: false);
    } catch (_) {
      // Fallback to local defaults
      state = state.copyWith(
        exercises: ExerciseModel.defaults,
        isLoading: false,
      );
    }
  }

  /// Start an exercise.
  void startExercise(ExerciseModel exercise) {
    state = state.copyWith(
      currentExercise: exercise,
      isCompleted: false,
    );
  }

  /// Mark the current exercise as completed.
  Future<void> completeCurrent({int? durationSeconds}) async {
    final exercise = state.currentExercise;
    if (exercise == null) return;

    try {
      await _repository.completeExercise(
        exercise.id,
        durationSeconds: durationSeconds,
      );
      state = state.copyWith(isCompleted: true);
    } catch (_) {
      // Silently fail — completion is non-critical
      state = state.copyWith(isCompleted: true);
    }
  }

  /// Clear the current exercise and go back to list.
  void clearCurrent() {
    state = state.copyWith(clearCurrent: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Main exercise controller provider.
final exerciseControllerProvider =
    StateNotifierProvider<ExerciseNotifier, ExerciseState>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return ExerciseNotifier(repository);
});
