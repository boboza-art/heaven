import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/exercise_controller.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// Quick Body Scan Exercise Page.
///
/// Guides users through a gentle head-to-toe body awareness
/// practice, checking in with each body region:
/// - Head & face
/// - Shoulders & arms
/// - Chest & belly
/// - Hips & lower back
/// - Legs & feet
///
/// Design follows Haven principles:
/// - No timer pressure — each step stays until user is ready
/// - Gentle, non-judgmental language
/// - Can pause, skip, or stop at any time
/// - Animation is soft and organic
class BodyScanExercisePage extends ConsumerStatefulWidget {
  const BodyScanExercisePage({super.key});

  @override
  ConsumerState<BodyScanExercisePage> createState() =>
      _BodyScanExercisePageState();
}

class _BodyScanExercisePageState extends ConsumerState<BodyScanExercisePage>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _isPaused = false;
  bool _isDone = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const _steps = [
    _BodyScanStep(
      title: '头部和面部',
      emoji: '🧠',
      guidance: '注意你的头部和面部。\n\n感受额头是紧绷还是放松？\n下巴是否微微用力？\n\n不需要改变什么，只是注意到它。',
      durationSeconds: 20,
    ),
    _BodyScanStep(
      title: '肩膀和手臂',
      emoji: '💪',
      guidance: '把注意力移到肩膀和手臂。\n\n肩膀是抬起来的还是自然下垂的？\n手臂放在哪里？\n\n如果感到紧张，可以轻轻动一下。',
      durationSeconds: 20,
    ),
    _BodyScanStep(
      title: '胸口和腹部',
      emoji: '🫁',
      guidance: '感受你的胸口和腹部。\n\n呼吸时，胸腔和腹部是如何起伏的？\n\n让呼吸自然地来，自然地去。',
      durationSeconds: 25,
    ),
    _BodyScanStep(
      title: '臀部和腰部',
      emoji: '🪑',
      guidance: '注意你的臀部和腰部。\n\n感受身体与椅子或地面的接触。\n\n这个支撑是稳定的，你不需要用力维持。',
      durationSeconds: 20,
    ),
    _BodyScanStep(
      title: '腿和脚',
      emoji: '🦶',
      guidance: '最后，把注意力放到腿和脚。\n\n感受脚底与地面的接触。\n\n从头到脚，你的身体一直在支撑着你。',
      durationSeconds: 20,
    ),
  ];

  Timer? _timer;
  int _secondsRemaining = 20;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    _secondsRemaining = _steps[0].durationSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || _isDone) return;
      setState(() {
        _secondsRemaining--;
      });
      if (_secondsRemaining <= 0) {
        _nextStep();
      }
    });
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
        _secondsRemaining = _steps[_currentStep].durationSeconds;
      });
    } else {
      _finishExercise();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _secondsRemaining = _steps[_currentStep].durationSeconds;
      });
    }
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  void _finishExercise() {
    _timer?.cancel();
    ref.read(exerciseControllerProvider.notifier).completeCurrent();
    setState(() => _isDone = true);
  }

  void _restart() {
    setState(() {
      _currentStep = 0;
      _isPaused = false;
      _isDone = false;
      _secondsRemaining = _steps[0].durationSeconds;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

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
          '快速身体扫描',
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
          child: _isDone ? _buildDoneView() : _buildStepView(step),
        ),
      ),
    );
  }

  Widget _buildStepView(_BodyScanStep step) {
    final progress = (_currentStep + 1) / _steps.length;

    return Column(
      children: [
        const SizedBox(height: HavenSpacing.md),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: HavenColors.textSecondary.withAlpha(30),
            valueColor: AlwaysStoppedAnimation(HavenColors.primary),
            minHeight: 4,
          ),
        ),

        const SizedBox(height: HavenSpacing.xxl),

        // Pulsing circle with emoji
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPaused ? 1.0 : _pulseAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      HavenColors.primary.withAlpha(40),
                      HavenColors.primary.withAlpha(10),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  step.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: HavenSpacing.xl),

        // Step title
        Text(
          step.title,
          style: HavenTypography.heading.copyWith(
            color: HavenColors.textPrimary,
          ),
        ),

        const SizedBox(height: HavenSpacing.sm),

        // Timer or paused indicator
        if (!_isPaused)
          Text(
            '$_secondsRemaining 秒',
            style: HavenTypography.caption.copyWith(
              color: HavenColors.textSecondary,
              fontSize: 15,
            ),
          )
        else
          Text(
            '已暂停',
            style: HavenTypography.caption.copyWith(
              color: HavenColors.textSecondary,
              fontSize: 15,
            ),
          ),

        const SizedBox(height: HavenSpacing.lg),

        // Guidance
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
              height: 1.8,
            ),
          ),
        ),

        const Spacer(),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous
            _ControlButton(
              icon: Icons.skip_previous,
              label: '上一部位',
              enabled: _currentStep > 0,
              onTap: _currentStep > 0 ? _previousStep : null,
            ),
            // Pause / Resume
            _ControlButton(
              icon: _isPaused ? Icons.play_arrow : Icons.pause,
              label: _isPaused ? '继续' : '暂停',
              onTap: _togglePause,
            ),
            // Next
            _ControlButton(
              icon: Icons.skip_next,
              label: '下一部位',
              onTap: _nextStep,
            ),
          ],
        ),

        const SizedBox(height: HavenSpacing.lg),

        // Step indicator
        Text(
          '第 ${_currentStep + 1} / ${_steps.length} 步',
          style: HavenTypography.caption.copyWith(
            color: HavenColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDoneView() {
    return Center(
      child: SingleChildScrollView(
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
              child: const Text('🧘', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: HavenSpacing.lg),
            Text(
              '扫描完成',
              style: HavenTypography.heading.copyWith(
                color: HavenColors.textPrimary,
              ),
            ),
            const SizedBox(height: HavenSpacing.sm),
            Text(
              '从头到脚，你照顾了你的身体',
              style: HavenTypography.body.copyWith(
                color: HavenColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HavenSpacing.lg),
            Text(
              '现在，带着这份觉察，\n慢慢回到你正在做的事情上。',
              textAlign: TextAlign.center,
              style: HavenTypography.body.copyWith(
                color: HavenColors.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: HavenSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _restart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HavenColors.primary,
                      side: BorderSide(color: HavenColors.primary.withAlpha(100)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '再来一次',
                      style: HavenTypography.body.copyWith(
                        color: HavenColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: HavenSpacing.md),
                SizedBox(
                  width: 130,
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
                      '完成',
                      style: HavenTypography.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = !enabled || onTap == null;
    final color = isDisabled
        ? HavenColors.textSecondary.withAlpha(60)
        : HavenColors.textPrimary;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HavenSpacing.md,
          vertical: HavenSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: HavenTypography.caption.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyScanStep {
  final String title;
  final String emoji;
  final String guidance;
  final int durationSeconds;

  const _BodyScanStep({
    required this.title,
    required this.emoji,
    required this.guidance,
    required this.durationSeconds,
  });
}
