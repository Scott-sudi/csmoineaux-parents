import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_providers.dart';
import '../shell/main_shell.dart';
import 'login_phone_screen.dart';

/// Point d'entrée : session parent → Accueil, sinon écran téléphone.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);

    return switch (session) {
      AuthSessionUnknown() || AuthSessionLoading() => const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      AuthSessionUnauthenticated() => const LoginPhoneScreen(),
      AuthSessionAuthenticated() => const MainShell(),
    };
  }
}
