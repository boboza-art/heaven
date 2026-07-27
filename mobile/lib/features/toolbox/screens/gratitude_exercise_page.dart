import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/exercise_controller.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// Three Good Things — Gratitude Journal Exercise.
///
/// Guides users to recall and write down three small things
/// that brought them warmth today.
///
/// Design follows Haven principles:
/// - Gentle prompts, not demanding
/// - "Small things" framing — no pressure for big achievements
/// - Can skip any entry
/// - Warm, affirming completion
class GratitudeExercisePage extends ConsumerStatefulWidget {
  const GratitudeExercisePage({super.key});

  @override
  ConsumerState<GratitudeExercisePage> createState() =>
      _GratitudeExercisePageState();
}

class _GratitudeExercisePageState extends ConsumerState<GratitudeExercisePage>
    with SingleTickerProviderStateMixin {
  final _controllers = List.generate(3, (_) => TextEditingController());
  late final AnimationController _fadeController;

  int _currentStep = 0; // 0, 1, 2 for entries, 3 for summary
  bool _isSubmitted = false;

  static const _prompts = [
    _GratitudePrompt(
      title: '第一件事',
      hint: '今天有什么让你感到温暖？\n可能是一顿好饭、一句问候、或者一个好天气……',
      emoji: '💛',
    ),
    _GratitudePrompt(
      title: '第二件事',
      hint: '再想一想，还有吗？\n也许是一个小小的帮助、一个笑容、或者一段安静的时间。',
      emoji: '🌿',
    ),
    _GratitudePrompt(
      title: '第三件事',
      hint: '最后一件事——\n哪怕很小很小都可以，只要让你有一点点好的感觉。',
      emoji: '✨',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController.forward();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _fadeController.forward(from: 0);
      if (_currentStep == 3) {
        _submit();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _fadeController.forward(from: 0);
    }
  }

  void _submit() {
    ref.read(exerciseControllerProvider.notifier).completeCurrent();
    setState(() => _isSubmitted = true);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          '三件好事',
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
          child: _currentStep < 3 && !_isSubmitted
              ? _buildEntryStep()
              : _isSubmitted
                  ? _buildSummaryView()
                  : _buildEntryStep(),
        ),
      ),
    );
  }

  Widget _buildEntryStep() {
    final prompt = _prompts[_currentStep];

    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: HavenSpacing.lg),

          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentStep ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i <= _currentStep
                      ? HavenColors.moodOkay
                      : HavenColors.textSecondary.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: HavenSpacing.xxl),

          // Emoji
          Center(
            child: Text(
              prompt.emoji,
              style: const TextStyle(fontSize: 48),
            ),
          ),

          const SizedBox(height: HavenSpacing.lg),

          // Title
          Center(
            child: Text(
              prompt.title,
              style: HavenTypography.heading.copyWith(
                color: HavenColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: HavenSpacing.md),

          // Hint
          Center(
            child: Text(
              prompt.hint,
              textAlign: TextAlign.center,
              style: HavenTypography.body.copyWith(
                color: HavenColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: HavenSpacing.xl),

          // Text input
          Expanded(
            child: TextField(
              controller: _controllers[_currentStep],
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: HavenTypography.body.copyWith(
                color: HavenColors.textPrimary,
                height: 1.6,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: HavenColors.moodOkay.withAlpha(80),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(HavenSpacing.lg),
                hintText: '写在这里……',
                hintStyle: HavenTypography.body.copyWith(
                  color: HavenColors.textSecondary.withAlpha(120),
                ),
              ),
            ),
          ),

          const SizedBox(height: HavenSpacing.md),

          // Navigation
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
                    backgroundColor: HavenColors.moodOkay,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  child: Text(
                    _currentStep < 2 ? '下一步' : '完成',
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
    );
  }

  Widget _buildSummaryView() {
    final entries = _controllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: HavenSpacing.xl),

          // Success emoji
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: HavenColors.moodOkay.withAlpha(30),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('💛', style: TextStyle(fontSize: 32)),
          ),

          const SizedBox(height: HavenSpacing.lg),

          Text(
            '谢谢你记录了这些',
            style: HavenTypography.heading.copyWith(
              color: HavenColors.textPrimary,
            ),
          ),

          const SizedBox(height: HavenSpacing.sm),

          Text(
            '这些小事，值得被记住',
            style: HavenTypography.body.copyWith(
              color: HavenColors.textSecondary,
            ),
          ),

          const SizedBox(height: HavenSpacing.xl),

          // Show entries
          ...entries.asMap().entries.map((entry) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: HavenSpacing.md),
              padding: const EdgeInsets.all(HavenSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key + 1}',
                    style: HavenTypography.body.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: HavenColors.moodOkay,
                    ),
                  ),
                  const SizedBox(width: HavenSpacing.md),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: HavenTypography.body.copyWith(
                        color: HavenColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          if (entries.isEmpty) ...[
            const SizedBox(height: HavenSpacing.xl),
            Text(
              '没关系，今天什么都不写也可以。\n知道你在试就已经很好了。',
              textAlign: TextAlign.center,
              style: HavenTypography.body.copyWith(
                color: HavenColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],

          const SizedBox(height: HavenSpacing.xl),

          // Done button
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

class _GratitudePrompt {
  final String title;
  final String hint;
  final String emoji;

  const _GratitudePrompt({
    required this.title,
    required this.hint,
    required this.emoji,
  });
}
