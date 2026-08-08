import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// En-tête Accueil : salutation + badge notifications.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.parentName,
    required this.notificationCount,
    this.onNotificationTap,
  });

  final String parentName;
  final int notificationCount;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 20,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Bonjour,\n',
                        style: TextStyle(fontWeight: FontWeight.w400),
                      ),
                      TextSpan(
                        text: '$parentName 👋',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bienvenue à Institut Kalunga',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNotificationTap,
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: notificationCount > 0,
              backgroundColor: AppColors.badge,
              label: Text(
                notificationCount > 99 ? '99+' : '$notificationCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
