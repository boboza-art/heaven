import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Welcome / Onboarding page.
///
/// First screen users see. Sets the tone for the entire app:
/// calm, warm, non-pressuring.
///
/// Shows two CTAs: login (for returning users) and register (for new users).
/// If the user is already authenticated, the router redirects to /today.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: HavenColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HavenSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: HavenColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: HavenColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: HavenSpacing.lg),
              Text(
                'Haven',
                style: HavenTypography.display.copyWith(
                  color: HavenColors.textPrimary,
                ),
              ),
              const SizedBox(height: HavenSpacing.sm),
              Text(
                '一个可以安心停留片刻的空间',
                style: HavenTypography.body.copyWith(
                  color: HavenColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HavenColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '登录',
                    style: HavenTypography.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HavenSpacing.md),
              // Register button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.go('/register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HavenColors.primary,
                    side: BorderSide(
                      color: HavenColors.primary.withAlpha(80),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    '注册新账号',
                    style: HavenTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HavenSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}
