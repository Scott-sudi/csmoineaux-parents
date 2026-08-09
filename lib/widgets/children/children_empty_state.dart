import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// État vide — maquette « Mes Enfants ».
class ChildrenEmptyState extends StatelessWidget {
  const ChildrenEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 72,
              color: AppColors.primary.withOpacity(0.45),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun enfant trouvé',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'avez aucun enfant lié à ce numéro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
