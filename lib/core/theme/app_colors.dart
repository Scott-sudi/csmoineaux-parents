import 'package:flutter/material.dart';

/// Palette fidèle au blason du C.S. Les Moineaux (marine / or).
abstract final class AppColors {
  static const Color primary = Color(0xFF0B1F4A);
  static const Color primaryLight = Color(0xFF14306E);
  static const Color accent = Color(0xFFC9A227);

  /// Aligné aussi sur le web (`--color-primary: #0b1f4a`) pour cohérence marque.
  static const Color brandWeb = Color(0xFF0B1F4A);

  static const Color background = Color(0xFFF5F7FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color divider = Color(0xFFE0E0E0);
  static const Color badge = Color(0xFF1B5E20);

  static const Color activityBulletin = Color(0xFF2E7D32);
  static const Color activityMeeting = Color(0xFFE65100);
  static const Color activityFees = Color(0xFF1565C0);

  static const Color lightGreen = Color(0xFFE8EEF7);
  static const Color inactiveBadge = Color(0xFF9E9E9E);
  static const Color inactiveBadgeBg = Color(0xFFEEEEEE);

  static const Color actionPresenceBg = Color(0xFFEBF5E9);
  static const Color actionAbsenceBg = Color(0xFFFFF3E0);
  static const Color actionDisciplineBg = Color(0xFFF3E5F5);
  static const Color actionPaymentBg = Color(0xFFE8F5E9);

  static const Color shadow = Color(0x1A000000);
}
