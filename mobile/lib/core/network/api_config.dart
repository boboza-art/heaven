/// API configuration for Haven backend.
///
/// Centralizes all API-related constants.
/// Base URL can be overridden for different environments:
/// - iOS Simulator: http://localhost:8000
/// - Android Emulator: http://10.0.2.2:8000
/// - Physical device: http://<your-ip>:8000
class ApiConfig {
  ApiConfig._();

  /// Base URL for the API.
  /// Change this based on your development environment.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// API version prefix.
  static const String apiPrefix = '/api/v1';

  /// Full API base URL.
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  /// Request timeout.
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
