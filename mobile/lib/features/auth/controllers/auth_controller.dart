import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/cache/local_cache.dart';
import '../models/auth_model.dart';
import '../state/auth_state.dart';

/// Auth state notifier.
///
/// Handles:
/// - register / login / logout
/// - restore session from stored tokens on app start
/// - automatic token persistence
class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;

  AuthNotifier(this._dio) : super(AuthState.initial);

  /// Restore session from stored tokens.
  ///
  /// Called on app start. If tokens exist, validates them with GET /auth/me.
  Future<void> restoreSession() async {
    if (!TokenStorage.hasToken) {
      state = state.copyWith(hasCheckedSession: true);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get('/auth/me');
      final user = UserModel.fromJson(response.data as Map<String, dynamic>);
      state = AuthState(
        user: user,
        hasCheckedSession: true,
      );
    } on DioException catch (e) {
      // Only clear tokens on 401 (invalid/expired). Network errors keep tokens.
      if (e.response?.statusCode == 401) {
        await TokenStorage.clear();
      }
      state = state.copyWith(hasCheckedSession: true, isLoading: false);
    } catch (_) {
      state = state.copyWith(hasCheckedSession: true, isLoading: false);
    }
  }

  /// Register a new account.
  Future<bool> register({
    required String email,
    required String password,
    String? nickname,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'nickname': nickname ?? 'Haven 用户',
      });

      final tokens = TokenPair.fromJson(response.data as Map<String, dynamic>);

      await TokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      // Fetch user info (AuthInterceptor will auto-inject the new token).
      final meResponse = await _dio.get('/auth/me');
      final user = UserModel.fromJson(meResponse.data as Map<String, dynamic>);

      state = AuthState(user: user, hasCheckedSession: true);
      return true;
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
        hasCheckedSession: true,
      );
      return false;
    }
  }

  /// Log in with email and password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final tokens = TokenPair.fromJson(response.data as Map<String, dynamic>);

      await TokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      // Fetch user info.
      final meResponse = await _dio.get('/auth/me');
      final user = UserModel.fromJson(meResponse.data as Map<String, dynamic>);

      state = AuthState(user: user, hasCheckedSession: true);
      return true;
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
        hasCheckedSession: true,
      );
      return false;
    }
  }

  /// Log out and clear all stored data.
  Future<void> logout() async {
    await TokenStorage.clear();
    await LocalCache.clearAll();
    state = const AuthState(hasCheckedSession: true);
  }

  /// Clear error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Extract a user-friendly error message from a DioException.
  String _extractError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return '无法连接服务器，请检查网络';
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // FastAPI returns {"detail": "..."} for errors.
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }

    if (statusCode == 401) return '邮箱或密码不正确';
    if (statusCode == 409) return '该邮箱已注册，请直接登录';
    if (statusCode != null && statusCode >= 500) return '服务器开小差了，请稍后再试';

    return '出错了，请稍后再试';
  }
}

/// Auth controller provider.
final authControllerProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthNotifier(dio);
});
