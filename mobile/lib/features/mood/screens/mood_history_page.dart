import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/mood_controller.dart';
import '../models/mood_model.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// Mood history and trend visualization page.
///
/// Shows:
/// - A simple line chart of recent mood entries (CustomPainter)
/// - A timeline list of all recorded moods
///
/// Design follows Haven principles:
/// - Calm, non-analytical tone — not a dashboard
/// - "Notice" rather than "analyze"
/// - Gentle colors and language
class MoodHistoryPage extends ConsumerStatefulWidget {
  const MoodHistoryPage({super.key});

  @override
  ConsumerState<MoodHistoryPage> createState() => _MoodHistoryPageState();
}

class _MoodHistoryPageState extends ConsumerState<MoodHistoryPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(moodControllerProvider.notifier).loadHistory();
    });
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
            Icons.arrow_back,
            color: HavenColors.textSecondary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '心情记录',
          style: HavenTypography.body.copyWith(
            color: HavenColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: state.isLoadingHistory
            ? const Center(child: CircularProgressIndicator())
            : state.history.isEmpty
                ? _buildEmptyState()
                : _buildContent(state.history),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HavenSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: HavenSpacing.lg),
            Text(
              '还没有记录',
              style: HavenTypography.heading.copyWith(
                color: HavenColors.textPrimary,
              ),
            ),
            const SizedBox(height: HavenSpacing.sm),
            Text(
              '开始记录心情后，\n这里会显示你的心情变化',
              textAlign: TextAlign.center,
              style: HavenTypography.body.copyWith(
                color: HavenColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<MoodModel> history) {
    // Reverse to show most recent first in the list
    final reversed = history.reversed.toList();
    final recentForChart = reversed.length > 14
        ? reversed.sublist(reversed.length - 14)
        : reversed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(HavenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(HavenSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最近的心情',
                  style: HavenTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: HavenColors.textPrimary,
                  ),
                ),
                const SizedBox(height: HavenSpacing.sm),
                Text(
                  '不用分析，只是看看它的变化',
                  style: HavenTypography.caption.copyWith(
                    color: HavenColors.textSecondary,
                  ),
                ),
                const SizedBox(height: HavenSpacing.lg),
                SizedBox(
                  height: 160,
                  child: CustomPaint(
                    painter: _MoodChartPainter(
                      moods: recentForChart,
                      moodColors: _moodColors,
                    ),
                    child: Container(),
                  ),
                ),
                const SizedBox(height: HavenSpacing.sm),
                // Chart legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _LegendDot(color: HavenColors.moodBad, label: '不好'),
                    _LegendDot(color: HavenColors.moodLow, label: '不太好'),
                    _LegendDot(color: HavenColors.moodOkay, label: '一般'),
                    _LegendDot(color: HavenColors.moodGood, label: '不错'),
                    _LegendDot(color: HavenColors.moodGreat, label: '很好'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: HavenSpacing.lg),

          // Section title
          Text(
            '记录列表',
            style: HavenTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: HavenColors.textPrimary,
            ),
          ),

          const SizedBox(height: HavenSpacing.md),

          // Timeline list
          ...reversed.map((mood) => _MoodTimelineEntry(mood: mood)),
        ],
      ),
    );
  }

  List<Color> get _moodColors => [
        HavenColors.moodBad,
        HavenColors.moodLow,
        HavenColors.moodOkay,
        HavenColors.moodGood,
        HavenColors.moodGreat,
      ];
}

/// Custom painter for the mood trend line chart.
class _MoodChartPainter extends CustomPainter {
  final List<MoodModel> moods;
  final List<Color> moodColors;

  _MoodChartPainter({
    required this.moods,
    required this.moodColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (moods.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final padding = 20.0;
    final chartW = w - padding * 2;
    final chartH = h - padding * 2;

    // Draw horizontal grid lines (5 levels)
    for (int i = 0; i <= 4; i++) {
      final y = padding + chartH * (1 - i / 4);
      final paint = Paint()
        ..color = HavenColors.textSecondary.withAlpha(20)
        ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(padding, y),
        Offset(w - padding, y),
        paint,
      );
    }

    if (moods.length == 1) {
      // Single point — just draw a dot
      final cx = w / 2;
      final cy = padding + chartH * (1 - (moods[0].moodLevel - 1) / 4);
      final paint = Paint()
        ..color = moodColors[moods[0].moodLevel - 1]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), 6, paint);
      return;
    }

    // Draw connecting line
    final linePaint = Paint()
      ..color = HavenColors.primary.withAlpha(100)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < moods.length; i++) {
      final x = padding + (moods.length == 1 ? 0 : chartW * i / (moods.length - 1));
      final y = padding + chartH * (1 - (moods[i].moodLevel - 1) / 4);
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Draw points with mood colors
    for (int i = 0; i < points.length; i++) {
      final color = moodColors[moods[i].moodLevel - 1];
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], 5, paint);

      // White border
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(points[i], 5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodChartPainter oldDelegate) {
    return oldDelegate.moods != moods;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: HavenTypography.caption.copyWith(
            fontSize: 11,
            color: HavenColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// A single mood entry in the timeline list.
class _MoodTimelineEntry extends StatelessWidget {
  final MoodModel mood;

  const _MoodTimelineEntry({required this.mood});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: HavenSpacing.sm),
      padding: const EdgeInsets.all(HavenSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Emoji
          Text(
            mood.emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: HavenSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood.label,
                  style: HavenTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: HavenColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(mood.createdAt),
                  style: HavenTypography.caption.copyWith(
                    color: HavenColors.textSecondary,
                  ),
                ),
                if (mood.hasNote) ...[
                  const SizedBox(height: 4),
                  Text(
                    mood.note!,
                    style: HavenTypography.caption.copyWith(
                      color: HavenColors.textPrimary.withAlpha(180),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
