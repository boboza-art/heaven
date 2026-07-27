import 'package:shared_preferences/shared_preferences.dart';

/// Token storage using SharedPreferences.
///
/// Persists access and refresh tokens across app restarts.
class TokenStorage {
  TokenStorage._();

  static const _keyAccessToken = 'haven_access_token';
  static const _keyRefreshToken = 'haven_refresh_token';

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences. Call once on app start.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError('TokenStorage not initialized. Call TokenStorage.init() first.');
    }
    return _prefs!;
  }

  /// Save both tokens.
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _instance.setString(_keyAccessToken, accessToken);
    await _instance.setString(_keyRefreshToken, refreshToken);
  }

  /// Get the current access token, or null if not logged in.
  static String? get accessToken => _instance.getString(_keyAccessToken);

  /// Get the current refresh token, or null if not logged in.
  static String? get refreshToken => _instance.getString(_keyRefreshToken);

  /// Whether tokens exist (user is potentially authenticated).
  static bool get hasToken => accessToken != null && accessToken!.isNotEmpty;

  /// Clear all stored tokens (logout).
  static Future<void> clear() async {
    await _instance.remove(_keyAccessToken);
    await _instance.remove(_keyRefreshToken);
  }
}
