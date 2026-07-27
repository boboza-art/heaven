import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../core/widgets/offline_banner.dart';
import '../mood/controllers/mood_controller.dart';
import '../memory/controllers/memory_controller.dart';
import '../auth/controllers/auth_controller.dart';

/// Today page — the main daily hub.
///
/// Shows:
/// - Greeting
/// - Current mood (if recorded) or mood check prompt
/// - Quick actions: chat, exercises
class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  @override
  void initState() {
    super.initState();
    // Load today's mood, history, and memory counts on page init
    Future.microtask(() {
      ref.read(moodControllerProvider.notifier).loadTodayMood();
      ref.read(moodControllerProvider.notifier).loadHistory();
      ref.read(memoryControllerProvider.notifier).loadMemories();
    });
  }

  Future<void> _openMoodCheck() async {
    final result = await context.push<bool>('/mood-check');

    // Refresh today's mood after returning from mood check
    if (result == true || result == null) {
      if (mounted) {
        ref.read(moodControllerProvider.notifier).loadTodayMood();
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '退出登录',
          style: HavenTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: HavenColors.textPrimary,
          ),
        ),
        content: Text(
          '确定要退出吗？下次需要重新登录。',
          style: HavenTypography.caption.copyWith(
            color: HavenColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              '取消',
              style: HavenTypography.caption.copyWith(
                color: HavenColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authControllerProvider.notifier).logout();
              if (mounted) context.go('/welcome');
            },
            child: Text(
              '退出',
              style: HavenTypography.caption.copyWith(
                color: HavenColors.moodBad,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final memoryState = ref.watch(memoryControllerProvider);

    return Scaffold(
      backgroundColor: HavenColors.background,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(HavenSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Top bar: today + logout
              Row(
                children: [
                  const SizedBox(width: HavenSpacing.sm),
                  Expanded(
                    child: Text(
                      '今天',
                      style: HavenTypography.heading.copyWith(
                        color: HavenColors.textPrimary,
                      ),
                    ),
                  ),
                  if (authState.isAuthenticated)
                    GestureDetector(
                      onTap: () => _showLogoutDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: HavenSpacing.sm,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.logout,
                              size: 16,
                              color: HavenColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '退出',
                              style: HavenTypography.caption.copyWith(
                                color: HavenColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: HavenSpacing.sm),
              Text(
                _greeting(moodState),
                style: HavenTypography.body.copyWith(
                  color: HavenColors.textSecondary,
                ),
              ),
              const SizedBox(height: HavenSpacing.xl),

              // Mood card — shows recorded mood or check-in prompt
              if (moodState.hasRecordedToday)
                _MoodRecordedCard(
                  mood: moodState.todayMood!,
                  onTap: _openMoodCheck,
                )
              else
                _ActionCard(
                  icon: Icons.sentiment_satisfied_alt_outlined,
                  title: '记录心情',
                  subtitle: '用一分钟了解自己的状态',
                  color: HavenColors.moodGood,
                  onTap: _openMoodCheck,
                ),

              const SizedBox(height: HavenSpacing.md),
              _ActionCard(
                icon: Icons.chat_bubble_outline,
                title: '聊一聊',
                subtitle: '和陪伴者说说心里话',
                color: HavenColors.secondary,
                onTap: () {
                  context.push('/chat');
                },
              ),
              const SizedBox(height: HavenSpacing.md),
              _ActionCard(
                icon: Icons.self_improvement_outlined,
                title: '小练习',
                subtitle: '花几分钟，照顾自己',
                color: HavenColors.moodGreat,
                onTap: () {
                  context.push('/exercises');
                },
              ),
              const SizedBox(height: HavenSpacing.md),
              _ActionCard(
                icon: Icons.psychology_outlined,
                title: '我的记忆',
                subtitle: memoryState.hasPending
                    ? '${memoryState.pendingCount} 条新记忆待审核'
                    : 'AI 记住了 ${memoryState.approvedCount} 件事',
                color: HavenColors.secondary,
                badge: memoryState.hasPending ? memoryState.pendingCount : null,
                onTap: () {
                  context.push('/memories');
                },
              ),

              // View mood history link
              if (moodState.history.isNotEmpty) ...[
                const SizedBox(height: HavenSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/mood-history'),
                    child: Text(
                      '查看心情记录',
                      style: HavenTypography.caption.copyWith(
                        color: HavenColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
              ],
            ),
          ), // Padding
        ), // SafeArea
          ), // Expanded
        ], // outer Column children
      ), // outer Column
    );
  }

  /// Gentle, context-aware greeting.
  String _greeting(MoodState moodState) {
    if (moodState.hasRecordedToday) {
      return '你已经记录了今天的心情';
    }
    final hour = DateTime.now().hour;
    if (hour < 12) return '早安，你今天感觉如何？';
    if (hour < 18) return '下午好，你今天感觉如何？';
    return '晚上好，你今天感觉如何？';
  }
}

/// Card showing the recorded mood for today.
class _MoodRecordedCard extends StatelessWidget {
  final dynamic mood; // MoodModel
  final VoidCallback onTap;

  const _MoodRecordedCard({
    required this.mood,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '今天的心情',
                  style: HavenTypography.caption.copyWith(
                    color: HavenColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '可以修改',
                  style: HavenTypography.caption.copyWith(
                    color: HavenColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: HavenColors.textSecondary.withAlpha(100),
                ),
              ],
            ),
            const SizedBox(height: HavenSpacing.sm),
            Row(
              children: [
                Text(
                  mood.emoji as String,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: HavenSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mood.label as String,
                      style: HavenTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: HavenColors.textPrimary,
                      ),
                    ),
                    if (mood.hasNote as bool)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          mood.note as String,
                          style: HavenTypography.caption.copyWith(
                            color: HavenColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final int? badge;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
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
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: HavenSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: HavenTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: HavenColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: HavenTypography.caption.copyWith(
                      color: HavenColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null && badge! > 0)
              Container(
                margin: const EdgeInsets.only(right: HavenSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: HavenColors.moodLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: HavenTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
