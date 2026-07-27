import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'token_storage.dart';

/// Authentication interceptor for Dio.
///
/// Automatically:
/// 1. Attaches the Bearer access token to every request
/// 2. On 401, attempts to refresh the token and retry the request
class AuthInterceptor extends Interceptor {
  /// Lock to prevent concurrent token refresh requests.
  Future<RequestOptions?>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = TokenStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Try to refresh the token (deduplicated — concurrent 401s share one refresh).
    final refreshed = await _tryRefresh(err.requestOptions);
    if (refreshed == null) {
      // Refresh failed — clear tokens and propagate the error.
      // The auth controller will handle redirecting to login.
      await TokenStorage.clear();
      return handler.next(err);
    }

    // Retry the original request with the new token.
    try {
      final response = await Dio().fetch(refreshed);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Attempt to refresh the access token.
  ///
  /// Returns the updated [RequestOptions] on success, or null on failure.
  /// Concurrent calls share the same refresh operation.
  Future<RequestOptions?> _tryRefresh(RequestOptions original) {
    return _refreshing ??= _doRefresh(original)
        .whenComplete(() => _refreshing = null);
  }

  Future<RequestOptions?> _doRefresh(RequestOptions original) async {
    final refreshToken = TokenStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
      ));

      final response = await dio.post(
        '${ApiConfig.apiPrefix}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccess = response.data['access_token'] as String;
        final newRefresh = response.data['refresh_token'] as String;

        await TokenStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );

        // Update the original request's auth header.
        original.headers['Authorization'] = 'Bearer $newAccess';
        return original;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return null;
  }
}
