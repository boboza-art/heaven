import 'package:flutter/material.dart';
import '../../models/mood_model.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// A gentle, non-pressuring mood selector widget.
///
/// Displays 5 mood options with emojis and labels.
/// Design follows Haven principles: calm, minimal, no pressure.
class MoodSelector extends StatelessWidget {
  /// Currently selected mood level (1-5).
  final int? selectedLevel;

  /// Called when the user selects a mood level.
  final ValueChanged<int> onMoodSelected;

  const MoodSelector({
    super.key,
    required this.selectedLevel,
    required this.onMoodSelected,
  });

  static const List<_MoodOption> _options = [
    _MoodOption(
      level: 1,
      emoji: '😞',
      label: '很不好',
      color: HavenColors.moodBad,
    ),
    _MoodOption(
      level: 2,
      emoji: '😕',
      label: '不太好',
      color: HavenColors.moodLow,
    ),
    _MoodOption(
      level: 3,
      emoji: '😐',
      label: '一般',
      color: HavenColors.moodOkay,
    ),
    _MoodOption(
      level: 4,
      emoji: '😊',
      label: '不错',
      color: HavenColors.moodGood,
    ),
    _MoodOption(
      level: 5,
      emoji: '😄',
      label: '很好',
      color: HavenColors.moodGreat,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _options.map((option) {
        final isSelected = selectedLevel == option.level;

        return GestureDetector(
          onTap: () => onMoodSelected(option.level),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: 56,
            padding: const EdgeInsets.symmetric(
              vertical: HavenSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? option.color.withAlpha(25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(
                      color: option.color.withAlpha(80),
                      width: 1.5,
                    )
                  : Border.all(
                      color: Colors.transparent,
                      width: 1.5,
                    ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.emoji,
                  style: TextStyle(
                    fontSize: isSelected ? 32 : 28,
                  ),
                ),
                const SizedBox(height: HavenSpacing.xs),
                Text(
                  option.label,
                  style: HavenTypography.caption.copyWith(
                    color: isSelected
                        ? option.color
                        : HavenColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MoodOption {
  final int level;
  final String emoji;
  final String label;
  final Color color;

  const _MoodOption({
    required this.level,
    required this.emoji,
    required this.label,
    required this.color,
  });
}
