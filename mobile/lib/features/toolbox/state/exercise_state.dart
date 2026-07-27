import '../models/exercise_model.dart';

/// UI state for the toolbox feature.
class ExerciseState {
  final List<ExerciseModel> exercises;
  final ExerciseModel? currentExercise;
  final bool isCompleted;
  final bool isLoading;
  final String? errorMessage;

  const ExerciseState({
    this.exercises = const [],
    this.currentExercise,
    this.isCompleted = false,
    this.isLoading = false,
    this.errorMessage,
  });

  static const ExerciseState initial = ExerciseState();

  ExerciseState copyWith({
    List<ExerciseModel>? exercises,
    ExerciseModel? currentExercise,
    bool? isCompleted,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearCurrent = false,
  }) {
    return ExerciseState(
      exercises: exercises ?? this.exercises,
      currentExercise: clearCurrent ? null : (currentExercise ?? this.currentExercise),
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
