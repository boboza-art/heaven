import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';
import '../cache/local_cache.dart';

/// Centralized Dio instance provider.
///
/// Configured with:
/// - Base URL from [ApiConfig]
/// - Connection and receive timeouts
/// - [AuthInterceptor] for automatic token injection and refresh
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.apiBaseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor());

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  return dio;
});

/// Initialize network layer (SharedPreferences).
///
/// Call this once before runApp, after WidgetsFlutterBinding.ensureInitialized().
Future<void> initNetwork() async {
  await TokenStorage.init();
  await LocalCache.init();
}
