import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/exercise_controller.dart';
import '../models/exercise_model.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import 'breathing_exercise_page.dart';
import 'grounding_exercise_page.dart';
import 'gratitude_exercise_page.dart';
import 'body_scan_exercise_page.dart';

/// Exercise list page.
///
/// Browse available self-help exercises, each with a
/// brief description and estimated duration.
class ExerciseListPage extends ConsumerStatefulWidget {
  const ExerciseListPage({super.key});

  @override
  ConsumerState<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends ConsumerState<ExerciseListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(exerciseControllerProvider.notifier).loadExercises();
    });
  }

  void _startExercise(ExerciseModel exercise) {
    ref.read(exerciseControllerProvider.notifier).startExercise(exercise);

    // Navigate based on exercise type
    Widget page;
    switch (exercise.id) {
      case 'breathing-478':
        page = const BreathingExercisePage();
        break;
      case 'grounding-54321':
        page = const GroundingExercisePage();
        break;
      case 'gratitude-journal':
        page = const GratitudeExercisePage();
        break;
      case 'body-scan-brief':
        page = const BodyScanExercisePage();
        break;
      default:
        page = _ExercisePlaceholderPage(exercise: exercise);
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseControllerProvider);

    return Scaffold(
      backgroundColor: HavenColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: HavenColors.textSecondary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '小练习',
          style: HavenTypography.body.copyWith(
            color: HavenColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.exercises.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(HavenSpacing.lg),
                    itemCount: state.exercises.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: HavenSpacing.md),
                    itemBuilder: (context, index) {
                      return _ExerciseCard(
                        exercise: state.exercises[index],
                        onTap: () => _startExercise(state.exercises[index]),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🧘', style: TextStyle(fontSize: 48)),
          const SizedBox(height: HavenSpacing.md),
          Text(
            '更多练习即将上线',
            style: HavenTypography.body.copyWith(
              color: HavenColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onTap;

  const _ExerciseCard({required this.exercise, required this.onTap});

  String get _icon {
    switch (exercise.category) {
      case 'breathing':
        return '🌬️';
      case 'grounding':
        return '🌱';
      case 'gratitude':
        return '💛';
      case 'body_scan':
        return '🧘';
      default:
        return '✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(HavenSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: HavenColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(_icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: HavenSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.title,
                    style: HavenTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: HavenColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.description,
                    style: HavenTypography.caption.copyWith(
                      color: HavenColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: HavenSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: HavenColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                exercise.durationText,
                style: HavenTypography.caption.copyWith(
                  color: HavenColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: HavenSpacing.xs),
            Icon(
              Icons.chevron_right,
              color: HavenColors.textSecondary.withAlpha(100),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for exercises not yet fully implemented.
class _ExercisePlaceholderPage extends StatelessWidget {
  final ExerciseModel exercise;

  const _ExercisePlaceholderPage({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HavenColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: HavenColors.textSecondary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(HavenSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🧘', style: TextStyle(fontSize: 48)),
                const SizedBox(height: HavenSpacing.lg),
                Text(
                  exercise.title,
                  style: HavenTypography.heading.copyWith(
                    color: HavenColors.textPrimary,
                  ),
                ),
                const SizedBox(height: HavenSpacing.sm),
                Text(
                  exercise.description,
                  style: HavenTypography.body.copyWith(
                    color: HavenColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: HavenSpacing.xxl),
                Text(
                  '即将上线',
                  style: HavenTypography.caption.copyWith(
                    color: HavenColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
