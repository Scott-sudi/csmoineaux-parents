import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Barre de navigation inférieure à 5 onglets (maquette).
class CustomBottomNavbar extends StatelessWidget {
  const CustomBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationBadge = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int notificationBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.card,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Mes Enfants',
            ),
            BottomNavigationBarItem(
              icon: _NavBadgeIcon(
                icon: Icons.notifications_none_outlined,
                count: notificationBadge,
                selected: false,
              ),
              activeIcon: _NavBadgeIcon(
                icon: Icons.notifications,
                count: notificationBadge,
                selected: true,
              ),
              label: 'Notifications',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              activeIcon: Icon(Icons.info),
              label: 'À propos',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Mon Compte',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBadgeIcon extends StatelessWidget {
  const _NavBadgeIcon({
    required this.icon,
    required this.count,
    required this.selected,
  });

  final IconData icon;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      backgroundColor: AppColors.badge,
      label: Text(
        '$count',
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      child: Icon(
        icon,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}
