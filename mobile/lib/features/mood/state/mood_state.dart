import '../models/mood_model.dart';

/// UI state for the mood feature.
///
/// Immutable state object consumed by Riverpod-based widgets.
class MoodState {
  /// Today's mood entry, if already recorded.
  final MoodModel? todayMood;

  /// Whether a mood save is in progress.
  final bool isSaving;

  /// Mood history for trend display.
  final List<MoodModel> history;

  /// Whether history is being loaded.
  final bool isLoadingHistory;

  /// Error message, if any.
  final String? errorMessage;

  const MoodState({
    this.todayMood,
    this.isSaving = false,
    this.history = const [],
    this.isLoadingHistory = false,
    this.errorMessage,
  });

  /// Initial/empty state.
  static const MoodState initial = MoodState();

  /// Whether the user has already recorded mood today.
  bool get hasRecordedToday => todayMood != null;

  MoodState copyWith({
    MoodModel? todayMood,
    bool? isSaving,
    List<MoodModel>? history,
    bool? isLoadingHistory,
    String? errorMessage,
    bool clearError = false,
    bool clearTodayMood = false,
  }) {
    return MoodState(
      todayMood: clearTodayMood ? null : (todayMood ?? this.todayMood),
      isSaving: isSaving ?? this.isSaving,
      history: history ?? this.history,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
