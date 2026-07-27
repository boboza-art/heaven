import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache backed by SharedPreferences.
///
/// Stores JSON-serializable data (lists of model JSON) for offline access.
/// Each data type gets its own key namespace.
///
/// Usage:
///   await LocalCache.saveList('mood_history', jsonList);
///   final cached = LocalCache.getList('mood_history');
class LocalCache {
  LocalCache._();

  static SharedPreferences? _prefs;

  static const _prefix = 'haven_cache_';

  /// Initialize SharedPreferences. Called once on app start.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError(
        'LocalCache not initialized. Call LocalCache.init() first.',
      );
    }
    return _prefs!;
  }

  /// Save a list of JSON maps under [key].
  static Future<void> saveList(String key, List<Map<String, dynamic>> items) async {
    final json = jsonEncode(items);
    await _instance.setString('$_prefix$key', json);
  }

  /// Retrieve a cached list of JSON maps, or null if not cached.
  static List<Map<String, dynamic>>? getList(String key) {
    final raw = _instance.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Save a single JSON map.
  static Future<void> saveJson(String key, Map<String, dynamic> data) async {
    await _instance.setString('$_prefix$key', jsonEncode(data));
  }

  /// Retrieve a cached JSON map, or null.
  static Map<String, dynamic>? getJson(String key) {
    final raw = _instance.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Remove a cached entry.
  static Future<void> remove(String key) async {
    await _instance.remove('$_prefix$key');
  }

  /// Clear all cached data (e.g., on logout).
  static Future<void> clearAll() async {
    final keys = _instance.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await _instance.remove(key);
    }
  }
}
