import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router/app_router.dart';
import '../theme/colors.dart';
import '../features/auth/controllers/auth_controller.dart';

class HavenApp extends ConsumerStatefulWidget {
  const HavenApp({super.key});

  @override
  ConsumerState<HavenApp> createState() => _HavenAppState();
}

class _HavenAppState extends ConsumerState<HavenApp> {
  @override
  void initState() {
    super.initState();
    // Restore auth session on app start
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // When auth state changes, refresh the router to re-evaluate redirects
    ref.listen(authControllerProvider, (previous, next) {
      router.refresh();
    });

    return MaterialApp.router(
      title: 'Haven',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: HavenColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
