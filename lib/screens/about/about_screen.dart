import 'package:flutter/material.dart';

import '../shell/placeholder_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'À propos',
      icon: Icons.info_outline,
      message:
          'Présentation de l’Institut Kalunga — La Source du Savoir.',
    );
  }
}
