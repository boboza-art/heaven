import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/exercise_controller.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// 4-7-8 Breathing Exercise Page.
///
/// Animated breathing circle that guides users through
/// the 4-7-8 breathing cycle:
/// - Breathe in (4 seconds)
/// - Hold (7 seconds)
/// - Breathe out (8 seconds)
///
/// Design follows Haven principles:
/// - Calm, gentle colors
/// - Non-pressuring language
/// - Can stop anytime
class BreathingExercisePage extends ConsumerStatefulWidget {
  const BreathingExercisePage({super.key});

  @override
  ConsumerState<BreathingExercisePage> createState() =>
      _BreathingExercisePageState();
}

enum _BreathingPhase { inhale, hold, exhale, done }

class _BreathingExercisePageState
    extends ConsumerState<BreathingExercisePage>
    with TickerProviderStateMixin {
  static const int _totalRounds = 3;
  static const int _inhaleSeconds = 4;
  static const int _holdSeconds = 7;
  static const int _exhaleSeconds = 8;

  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  Timer? _timer;
  int _currentRound = 1;
  _BreathingPhase _phase = _BreathingPhase.inhale;
  int _secondsRemaining = _inhaleSeconds;
  bool _isPaused = false;

  // Breath circle sizes
  static const double _minSize = 120;
  static const double _maxSize = 200;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startPhase(_BreathingPhase.inhale);
  }

  void _setupAnimation() {
    _scaleController = AnimationController(
      duration: const Duration(seconds: _inhaleSeconds),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: _minSize, end: _maxSize).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOutCubic),
    );
  }

  void _startPhase(_BreathingPhase phase) {
    _timer?.cancel();
    setState(() {
      _phase = phase;
      _secondsRemaining = _getPhaseDuration(phase);
    });

    // Animate circle: inhale = expand, exhale = contract, hold = stay
    _scaleController.stop();
    if (phase == _BreathingPhase.inhale) {
      _scaleController.duration = const Duration(seconds: _inhaleSeconds);
      _scaleController.forward(from: 0);
    } else if (phase == _BreathingPhase.exhale) {
      _scaleController.duration = const Duration(seconds: _exhaleSeconds);
      _scaleController.reverse(from: 1);
    }

    // Countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused) return;

      setState(() {
        _secondsRemaining--;
      });

      if (_secondsRemaining <= 0) {
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    switch (_phase) {
      case _BreathingPhase.inhale:
        _startPhase(_BreathingPhase.hold);
        break;
      case _BreathingPhase.hold:
        _startPhase(_BreathingPhase.exhale);
        break;
      case _BreathingPhase.exhale:
        if (_currentRound < _totalRounds) {
          _currentRound++;
          _startPhase(_BreathingPhase.inhale);
        } else {
          _finishExercise();
        }
        break;
      case _BreathingPhase.done:
        break;
    }
  }

  void _finishExercise() {
    _timer?.cancel();
    _scaleController.stop();
    setState(() {
      _phase = _BreathingPhase.done;
      _secondsRemaining = 0;
    });
    // Total duration = rounds * (inhale + hold + exhale)
    final totalSeconds = _totalRounds * (_inhaleSeconds + _holdSeconds + _exhaleSeconds);
    ref.read(exerciseControllerProvider.notifier).completeCurrent(
      durationSeconds: totalSeconds,
    );
  }

  int _getPhaseDuration(_BreathingPhase phase) {
    switch (phase) {
      case _BreathingPhase.inhale:
        return _inhaleSeconds;
      case _BreathingPhase.hold:
        return _holdSeconds;
      case _BreathingPhase.exhale:
        return _exhaleSeconds;
      case _BreathingPhase.done:
        return 0;
    }
  }

  String get _phaseLabel {
    switch (_phase) {
      case _BreathingPhase.inhale:
        return '吸气';
      case _BreathingPhase.hold:
        return '屏息';
      case _BreathingPhase.exhale:
        return '呼气';
      case _BreathingPhase.done:
        return '完成';
    }
  }

  String get _guidanceText {
    switch (_phase) {
      case _BreathingPhase.inhale:
        return '慢慢地，用鼻子吸气';
      case _BreathingPhase.hold:
        return '轻轻地，停留在这里';
      case _BreathingPhase.exhale:
        return '缓缓地，用嘴巴呼气';
      case _BreathingPhase.done:
        return '你做得很好';
    }
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _scaleController.stop();
    } else {
      // Resume animation from current phase
      if (_phase == _BreathingPhase.inhale) {
        _scaleController.forward();
      } else if (_phase == _BreathingPhase.exhale) {
        _scaleController.reverse();
      }
    }
  }

  void _restart() {
    setState(() {
      _currentRound = 1;
      _isPaused = false;
    });
    _startPhase(_BreathingPhase.inhale);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDone = _phase == _BreathingPhase.done;

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
          '4-7-8 呼吸法',
          style: HavenTypography.body.copyWith(
            color: HavenColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(HavenSpacing.xl),
            child: Column(
              children: [
                const SizedBox(height: HavenSpacing.xl),

                // Progress indicator
                if (!isDone) ...[
                  Text(
                    '第 $_currentRound / $_totalRounds 轮',
                    style: HavenTypography.caption.copyWith(
                      color: HavenColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: HavenSpacing.xl),
                ],

                // Animated breathing circle
                GestureDetector(
                  onTap: isDone ? _restart : null,
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      final currentSize =
                          _phase == _BreathingPhase.hold
                              ? _maxSize // hold at max
                              : _scaleAnimation.value;

                      return Container(
                        width: currentSize,
                        height: currentSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: isDone
                                ? [
                                    HavenColors.moodGreat.withAlpha(60),
                                    HavenColors.moodGreat.withAlpha(15),
                                  ]
                                : _phase == _BreathingPhase.hold
                                    ? [
                                        HavenColors.secondary.withAlpha(80),
                                        HavenColors.secondary.withAlpha(20),
                                      ]
                                    : [
                                        HavenColors.primary.withAlpha(60),
                                        HavenColors.primary.withAlpha(15),
                                      ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isDone ? '✓' : '$_secondsRemaining',
                            style: TextStyle(
                              fontSize: isDone ? 36 : 32,
                              fontWeight: FontWeight.w300,
                              color: isDone
                                  ? HavenColors.moodGreat
                                  : HavenColors.textPrimary.withAlpha(180),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: HavenSpacing.xxl),

                // Phase label
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    isDone ? '完成练习' : _phaseLabel,
                    key: ValueKey(_phase),
                    style: HavenTypography.display.copyWith(
                      color: HavenColors.textPrimary,
                      fontSize: 28,
                    ),
                  ),
                ),

                const SizedBox(height: HavenSpacing.sm),

                // Guidance text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    isDone ? '给自己一点时间感受这一刻' : _guidanceText,
                    key: ValueKey(_guidanceText),
                    style: HavenTypography.body.copyWith(
                      color: HavenColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: HavenSpacing.xxl),

                // Controls
                if (isDone)
                  Column(
                    children: [
                      SizedBox(
                        width: size.width * 0.6,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _restart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HavenColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            '再来一次',
                            style: HavenTypography.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: HavenSpacing.md),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          '回到练习列表',
                          style: HavenTypography.body.copyWith(
                            color: HavenColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pause / Resume
                      _ControlButton(
                        icon: _isPaused ? Icons.play_arrow : Icons.pause,
                        label: _isPaused ? '继续' : '暂停',
                        onTap: _togglePause,
                      ),
                      const SizedBox(width: HavenSpacing.xxl),
                      // Skip
                      _ControlButton(
                        icon: Icons.skip_next,
                        label: '跳过',
                        onTap: _nextPhase,
                      ),
                    ],
                  ),

                if (_isPaused && !isDone) ...[
                  const SizedBox(height: HavenSpacing.md),
                  Text(
                    '已暂停 — 准备好了随时继续',
                    style: HavenTypography.caption.copyWith(
                      color: HavenColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HavenSpacing.lg,
          vertical: HavenSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: HavenColors.textPrimary, size: 20),
            const SizedBox(width: HavenSpacing.xs),
            Text(
              label,
              style: HavenTypography.caption.copyWith(
                color: HavenColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
