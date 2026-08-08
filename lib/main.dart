import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/dependency_providers.dart';
import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sur web, évite le blocage de flutter_secure_storage au démarrage.
  final storage = await SecureStorageService.create();

  runApp(
    ProviderScope(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
      ],
      child: const KalungaParentsApp(),
    ),
  );
}

/// Application mobile parents — Institut Kalunga.
class KalungaParentsApp extends StatelessWidget {
  const KalungaParentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Institut Kalunga',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
