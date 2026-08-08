import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final name = switch (session) {
      AuthSessionAuthenticated(:final identity)
          when identity.displayName.isNotEmpty =>
        identity.displayName,
      _ => 'Parent',
    };
    final phone = switch (session) {
      AuthSessionAuthenticated(:final identity) => identity.phone,
      _ => '',
    };

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(
                Icons.person_outline,
                size: 56,
                color: AppColors.primaryLight,
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(authSessionProvider.notifier).logout();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusButton,
                    ),
                  ),
                ),
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
