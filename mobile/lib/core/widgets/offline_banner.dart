import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/connectivity_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// A compact banner shown when the device is offline.
///
/// Displays "离线模式" with a subtle amber background.
/// Automatically appears/disappears based on connectivity state.
/// Tap to retry the connection check.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider);

    if (isOnline) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFFF59E0B), // Amber
      child: InkWell(
        onTap: () {
          ref.read(connectivityProvider.notifier).check();
        },
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HavenSpacing.md,
              vertical: HavenSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: HavenSpacing.sm),
                Expanded(
                  child: Text(
                    '离线模式 — 正在显示缓存数据，点击重试连接',
                    style: HavenTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.refresh,
                  size: 16,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
