import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/onboarding/welcome_page.dart';
import '../features/today/today_page.dart';
import '../features/mood/screens/mood_check_page.dart';
import '../features/mood/screens/mood_history_page.dart';
import '../features/toolbox/screens/exercise_list_page.dart';
import '../features/chat/screens/chat_page.dart';
import '../features/auth/screens/login_page.dart';
import '../features/auth/screens/register_page.dart';
import '../features/memory/screens/memory_page.dart';
import '../features/auth/controllers/auth_controller.dart';

/// Route paths — centralized for consistency.
class AppRoutes {
  AppRoutes._();

  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const today = '/today';
  static const moodCheck = '/mood-check';
  static const moodHistory = '/mood-history';
  static const chat = '/chat';
  static const exercises = '/exercises';
  static const memories = '/memories';
}

/// GoRouter provider with auth redirect.
///
/// Uses `ref.read` inside the redirect (not `ref.watch`) to avoid
/// recreating the router on every auth state change. The HavenApp
/// listens for auth changes and calls `router.refresh()` instead.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    redirect: (context, state) {
      // Read current auth state (not watch — avoids router recreation)
      final authState = ref.read(authControllerProvider);
      final isAuthenticated = authState.isAuthenticated;
      final hasChecked = authState.hasCheckedSession;
      final currentPath = state.matchedLocation;

      // While session is being restored, stay on current route
      if (!hasChecked) return null;

      // Public routes — allow access without auth
      final isPublicRoute = currentPath == AppRoutes.welcome ||
          currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register;

      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }

      // If already authenticated and on welcome/login/register → go to today
      if (isAuthenticated && isPublicRoute) {
        return AppRoutes.today;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.today,
        builder: (context, state) => const TodayPage(),
      ),
      GoRoute(
        path: AppRoutes.moodCheck,
        builder: (context, state) => const MoodCheckPage(),
      ),
      GoRoute(
        path: AppRoutes.moodHistory,
        builder: (context, state) => const MoodHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => const ChatPage(),
      ),
      GoRoute(
        path: AppRoutes.exercises,
        builder: (context, state) => const ExerciseListPage(),
      ),
      GoRoute(
        path: AppRoutes.memories,
        builder: (context, state) => const MemoryPage(),
      ),
    ],
  );
});
