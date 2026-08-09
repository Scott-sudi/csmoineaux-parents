import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/dependency_providers.dart';
import 'providers/settings_providers.dart';
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
class KalungaParentsApp extends ConsumerWidget {
  const KalungaParentsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(appLanguageProvider);

    return MaterialApp(
      title: 'Institut Kalunga',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: language.materialLocale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}
