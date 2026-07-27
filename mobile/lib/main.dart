/// Haven - AI Emotional Support App
/// Main entry point

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/haven_app.dart';
import 'core/network/dio_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize network layer (SharedPreferences for token storage)
  await initNetwork();

  runApp(
    const ProviderScope(
      child: HavenApp(),
    ),
  );
}
