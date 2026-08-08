import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/home_providers.dart';
import '../../widgets/navigation/custom_bottom_navbar.dart';
import '../about/about_screen.dart';
import '../account/account_screen.dart';
import '../children/children_screen.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';

/// Coquille principale : Accueil + 4 onglets placeholders navigables.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(bottomNavIndexProvider);
    final dashboard = ref.watch(homeDashboardProvider);
    final badge = dashboard.maybeWhen(
      data: (d) => d.overview.unreadNotificationsBadge,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: index,
          children: [
            HomeScreen(
              onOpenNotifications: () {
                ref.read(bottomNavIndexProvider.notifier).state = 2;
              },
            ),
            const ChildrenScreen(),
            const NotificationsScreen(),
            const AboutScreen(),
            const AccountScreen(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: index,
        notificationBadge: badge,
        onTap: (value) {
          ref.read(bottomNavIndexProvider.notifier).state = value;
        },
      ),
    );
  }
}
