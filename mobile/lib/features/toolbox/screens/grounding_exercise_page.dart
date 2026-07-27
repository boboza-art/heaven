import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/exercise_controller.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// 5-4-3-2-1 Grounding Exercise Page.
///
/// Guides users through engaging their five senses to return
/// to the present moment:
/// - 5 things you can see
/// - 4 things you can hear
/// - 3 things you can touch
/// - 2 things you can smell
/// - 1 thing you can taste
///
/// Design follows Haven principles:
/// - No timer, no pressure — proceed at own pace
/// - Gentle, sensory-focused language
/// - Can stop anytime
class GroundingExercisePage extends ConsumerStatefulWidget {
  const GroundingExercisePage({super.key});

  @override
  ConsumerState<GroundingExercisePage> createState() =>
      _GroundingExercisePageState();
}

class _GroundingExercisePageState extends ConsumerState<GroundingExercisePage>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  static const _steps = [
    _GroundingStep(
      count: 5,
      sense: '看',
      emoji: '👀',
      prompt: '慢慢地环顾四周',
      guidance: '找出 5 样你能看到的东西。\n可以是任何东西——一盏灯、窗外的一棵树、桌上的杯子。',
    ),
    _GroundingStep(
      count: 4,
      sense: '听',
      emoji: '👂',
      prompt: '闭上眼睛，听一听',
      guidance: '找出 4 种你能听到的声音。\n远处的车声、空调的嗡嗡声、自己的呼吸声……',
    ),
    _GroundingStep(
      count: 3,
      sense: '触摸',
      emoji: '✋',
      prompt: '感受你的触觉',
      guidance: '找出 3 样你能触摸到的东西。\n衣服的质地、椅子的温度、手指间的空气。',
    ),
    _GroundingStep(
      count: 2,
      sense: '闻',
      emoji: '👃',
      prompt: '轻轻吸一口气',
      guidance: '找出 2 种你能闻到的气味。\n咖啡的香气、书本的纸味、空气的清新。',
    ),
    _GroundingStep(
      count: 1,
      sense: '尝',
      emoji: '👅',
      prompt: '注意你的味觉',
      guidance: '找出 1 种你能尝到的味道。\n嘴里残留的茶味、水的味道，或者只是空气的味道。',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _fadeController.forward(from: 0);
    } else {
      _finishExercise();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _fadeController.forward(from: 0);
    }
  }

  void _finishExercise() {
    ref.read(exerciseControllerProvider.notifier).completeCurrent();
    setState(() => _currentStep = -1);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _currentStep == -1;
    final step = isDone ? null : _steps[_currentStep];

    return Scaffold(
      backgroundColor: HavenColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: HavenColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '5-4-3-2-1 感官练习',
          style: HavenTypography.body.copyWith(
            color: HavenColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HavenSpacing.xl),
          child: isDone
              ? _buildDoneView()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildStepView(step!),
                ),
        ),
      ),
    );
  }

  Widget _buildStepView(_GroundingStep step) {
    final progress = (_currentStep + 1) / _steps.length;

    return Column(
      children: [
        const SizedBox(height: HavenSpacing.xl),

        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _steps.length,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentStep ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i <= _currentStep
                    ? HavenColors.primary
                    : HavenColors.textSecondary.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        const SizedBox(height: HavenSpacing.xxl),

        // Sense emoji
        Text(
          step.emoji,
          style: const TextStyle(fontSize: 56),
        ),

        const SizedBox(height: HavenSpacing.lg),

        // Count
        Text(
          '${step.count}',
          style: HavenTypography.display.copyWith(
            fontSize: 48,
            fontWeight: FontWeight.w200,
            color: HavenColors.primary,
          ),
        ),

        const SizedBox(height: HavenSpacing.xs),

        // Sense label
        Text(
          '${step.sense}',
          style: HavenTypography.heading.copyWith(
            color: HavenColors.textPrimary,
          ),
        ),

        const SizedBox(height: HavenSpacing.md),

        // Prompt
        Text(
          step.prompt,
          style: HavenTypography.body.copyWith(
            color: HavenColors.textSecondary,
          ),
        ),

        const SizedBox(height: HavenSpacing.xl),

        // Guidance text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(HavenSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            step.guidance,
            textAlign: TextAlign.center,
            style: HavenTypography.body.copyWith(
              color: HavenColors.textPrimary,
              height: 1.7,
            ),
          ),
        ),

        const Spacer(),

        // Navigation buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0)
              TextButton(
                onPressed: _previousStep,
                child: Text(
                  '上一步',
                  style: HavenTypography.body.copyWith(
                    color: HavenColors.textSecondary,
                  ),
                ),
              )
            else
              const SizedBox(width: 60),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HavenColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                ),
                child: Text(
                  _currentStep < _steps.length - 1 ? '下一步' : '完成',
                  style: HavenTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: HavenSpacing.lg),

        // Progress hint
        Text(
          '${_currentStep + 1} / ${_steps.length}',
          style: HavenTypography.caption.copyWith(
            color: HavenColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDoneView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: HavenColors.moodGreat.withAlpha(30),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🌱', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: HavenSpacing.lg),
          Text(
            '你回到了此刻',
            style: HavenTypography.heading.copyWith(
              color: HavenColors.textPrimary,
            ),
          ),
          const SizedBox(height: HavenSpacing.sm),
          Text(
            '花一点时间，感受一下现在的自己',
            style: HavenTypography.body.copyWith(
              color: HavenColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: HavenSpacing.xxl),
          SizedBox(
            width: 200,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: HavenColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                '回到练习列表',
                style: HavenTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroundingStep {
  final int count;
  final String sense;
  final String emoji;
  final String prompt;
  final String guidance;

  const _GroundingStep({
    required this.count,
    required this.sense,
    required this.emoji,
    required this.prompt,
    required this.guidance,
  });
}
