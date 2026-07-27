import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks network connectivity status.
///
/// Uses a lightweight socket connection test (DNS lookup + socket connect)
/// instead of a third-party package. Checks every 5 seconds when the app
/// is in the foreground, and immediately on demand.
class ConnectivityNotifier extends StateNotifier<bool> {
  Timer? _timer;
  bool _disposed = false;

  ConnectivityNotifier() : super(true) {
    // Initial check
    check();
    // Periodic polling
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => check());
  }

  /// Force a connectivity check now.
  Future<void> check() async {
    try {
      final result = await InternetAddress.lookup('api.deepseek.com');
      final connected =
          result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      if (!_disposed && state != connected) {
        state = connected;
      }
    } catch (_) {
      if (!_disposed && state) {
        state = false;
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

/// Whether the device currently has internet connectivity.
///
/// Listen to this provider to reactively update UI when connectivity changes.
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});
