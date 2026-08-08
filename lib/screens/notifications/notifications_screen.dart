import 'package:flutter/material.dart';

import '../shell/placeholder_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Notifications',
      icon: Icons.notifications_none_outlined,
      message:
          'Les notifications parents (bulletins, réunions, frais) arriveront ici.',
    );
  }
}
