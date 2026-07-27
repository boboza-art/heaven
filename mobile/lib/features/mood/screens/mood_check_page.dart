import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/mood_controller.dart';
import '../widgets/mood_selector.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// Mood check page.
///
/// Full-screen experience for users to:
/// 1. Select how they feel (5-level mood picker)
/// 2. Optionally add a note
/// 3. Save the entry
///
/// Design follows Haven principles:
/// - Clean, minimal layout
/// - Gentle language
/// - No pressure to proceed
/// - Supports going back without saving
class MoodCheckPage extends ConsumerStatefulWidget {
  const MoodCheckPage({super.key});

  @override
  ConsumerState<MoodCheckPage> createState() => _MoodCheckPageState();
}

class _MoodCheckPageState extends ConsumerState<MoodCheckPage> {
  int? _selectedLevel;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    if (_selectedLevel == null) return;

    final success = await ref.read(moodControllerProvider.notifier).recordMood(
          moodLevel: _selectedLevel!,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    if (success && mounted) {
      // Show a gentle confirmation, then go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已记录'),
          backgroundColor: HavenColors.primary.withAlpha(220),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moodControllerProvider);

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
        actions: [
          if (_selectedLevel != null)
            Padding(
              padding: const EdgeInsets.only(right: HavenSpacing.sm),
              child: TextButton(
                onPressed: state.isSaving ? null : _saveMood,
                child: state.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '完成',
                        style: HavenTypography.body.copyWith(
                          color: HavenColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(HavenSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Text(
                  '你今天感觉如何？',
                  style: HavenTypography.heading.copyWith(
                    color: HavenColors.textPrimary,
                  ),
                ),
                const SizedBox(height: HavenSpacing.sm),
                Text(
                  '没有对错之分，选一个和现在的你最接近的',
                  style: HavenTypography.body.copyWith(
                    color: HavenColors.textSecondary,
                  ),
                ),

                const SizedBox(height: HavenSpacing.xxl),

                // Mood selector
                Center(
                  child: MoodSelector(
                    selectedLevel: _selectedLevel,
                    onMoodSelected: (level) {
                      setState(() => _selectedLevel = level);
                    },
                  ),
                ),

                // Show selected mood info
                if (_selectedLevel != null) ...[
                  const SizedBox(height: HavenSpacing.xxl),
                  _buildSelectedMoodInfo(),
                ],

                // Note input — only show after mood is selected
                if (_selectedLevel != null) ...[
                  const SizedBox(height: HavenSpacing.xl),
                  _buildNoteInput(),
                ],

                // Error message
                if (state.errorMessage != null) ...[
                  const SizedBox(height: HavenSpacing.lg),
                  _buildErrorMessage(state.errorMessage!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedMoodInfo() {
    // Find the mood emoji for the selected level
    final mood = MoodModel.now(moodLevel: _selectedLevel!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HavenSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(mood.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: HavenSpacing.md),
          Text(
            '你选择了「${mood.label}」',
            style: HavenTypography.body.copyWith(
              color: HavenColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '想多说两句吗？（选填）',
          style: HavenTypography.body.copyWith(
            color: HavenColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: HavenSpacing.sm),
        TextField(
          controller: _noteController,
          maxLines: 3,
          maxLength: 200,
          style: HavenTypography.body.copyWith(
            color: HavenColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '比如说，今天发生了什么...',
            hintStyle: HavenTypography.body.copyWith(
              color: HavenColors.textSecondary.withAlpha(150),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: HavenColors.primary.withAlpha(80),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(HavenSpacing.md),
            counterStyle: HavenTypography.caption.copyWith(
              color: HavenColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HavenSpacing.md),
      decoration: BoxDecoration(
        color: HavenColors.moodBad.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: HavenColors.moodBad,
            size: 18,
          ),
          const SizedBox(width: HavenSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: HavenTypography.caption.copyWith(
                color: HavenColors.moodBad,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
