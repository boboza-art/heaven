import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_model.dart';
import '../repositories/mood_repository.dart';
import '../../../core/network/dio_provider.dart';
import 'mood_state.dart';

/// Repository provider — uses caching decorator with offline resilience.
///
/// Wraps [ApiMoodRepository] in [CachingMoodRepository]:
/// - Online: calls API, caches results to [LocalCache].
/// - Offline: returns cached data, saves new moods locally.
final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CachingMoodRepository(ApiMoodRepository(dio));
});

/// Mood state notifier.
///
/// Handles all business logic for mood recording and retrieval.
class MoodNotifier extends StateNotifier<MoodState> {
  final MoodRepository _repository;

  MoodNotifier(this._repository) : super(MoodState.initial);

  /// Load today's mood on app start.
  Future<void> loadTodayMood() async {
    try {
      final mood = await _repository.getTodayMood();
      state = state.copyWith(todayMood: mood);
    } catch (e) {
      // Silently fail — mood is optional
    }
  }

  /// Record a new mood entry.
  Future<bool> recordMood({
    required int moodLevel,
    String? note,
  }) async {
    if (moodLevel < 1 || moodLevel > 5) return false;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final mood = MoodModel.now(moodLevel: moodLevel, note: note);
      final saved = await _repository.saveMood(mood);

      final resultMood = saved ?? mood;
      state = state.copyWith(
        todayMood: resultMood,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '保存失败，请再试一次',
      );
      return false;
    }
  }

  /// Load mood history for trend view.
  Future<void> loadHistory() async {
    state = state.copyWith(isLoadingHistory: true);
    try {
      final history = await _repository.getMoodHistory();
      state = state.copyWith(
        history: history,
        isLoadingHistory: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  /// Clear error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset the today's mood (for development/testing).
  void resetTodayMood() {
    state = state.copyWith(clearTodayMood: true);
  }
}

/// The main mood controller provider.
final moodControllerProvider =
    StateNotifierProvider<MoodNotifier, MoodState>((ref) {
  final repository = ref.watch(moodRepositoryProvider);
  return MoodNotifier(repository);
});
