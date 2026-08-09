import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settings_providers.dart';
import 'help_support_screen.dart';
import 'personal_info_screen.dart';

/// Onglet Mon Compte — maquette écran 5 (profil + paramètres + déconnexion).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final language = ref.watch(appLanguageProvider);
    final themeMode = ref.watch(themeModeProvider);
    final s = ref.watch(appStringsProvider);
    final themeLabel = switch (themeMode) {
      ThemeMode.dark => s.themeDark,
      ThemeMode.system => s.themeSystem,
      ThemeMode.light => s.themeLight,
    };

    final name = switch (session) {
      AuthSessionAuthenticated(:final identity)
          when identity.displayName.isNotEmpty =>
        identity.displayName,
      _ => 'Parent',
    };
    final phone = switch (session) {
      AuthSessionAuthenticated(:final identity) => identity.phone.trim(),
      _ => '',
    };
    final email = switch (session) {
      AuthSessionAuthenticated(:final identity) => identity.email.trim(),
      _ => '',
    };

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          s.accountTitle,
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _ProfileHeader(
            name: name,
            phone: phone,
            email: email,
            roleLabel: s.parentTutor,
          ),
          const SizedBox(height: 28),
          _SectionLabel(s.accountSettings),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                label: s.personalInfo,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PersonalInfoScreen(),
                    ),
                  );
                },
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.language,
                label: s.languageMenu,
                trailingValue: language.label,
                onTap: () => _pickLanguage(context, ref, s),
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: themeMode == ThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.wb_sunny_outlined,
                label: s.theme,
                trailingValue: themeLabel,
                onTap: () => _pickTheme(context, ref, s),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(s.others),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                label: s.helpSupport,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(),
                    ),
                  );
                },
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.logout,
                label: s.logout,
                destructive: true,
                showChevron: false,
                onTap: () => _confirmLogout(context, ref, s),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
  ) async {
    final current = ref.read(appLanguageProvider);
    final selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: context.appCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  s.languageMenu,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ctx.appTextPrimary,
                  ),
                ),
              ),
              for (final lang in AppLanguage.values)
                ListTile(
                  title: Text(
                    lang.label,
                    style: TextStyle(color: ctx.appTextPrimary),
                  ),
                  trailing: lang == current
                      ? Icon(Icons.check, color: ctx.appPrimary)
                      : null,
                  onTap: () => Navigator.pop(ctx, lang),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      await ref.read(appLanguageProvider.notifier).setLanguage(selected);
    }
  }

  static Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
  ) async {
    final current = ref.read(themeModeProvider);
    final options = <(ThemeMode, String, IconData)>[
      (ThemeMode.light, s.themeLight, Icons.wb_sunny_outlined),
      (ThemeMode.dark, s.themeDark, Icons.dark_mode_outlined),
      (ThemeMode.system, s.themeSystem, Icons.settings_suggest_outlined),
    ];
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: context.appCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  s.theme,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ctx.appTextPrimary,
                  ),
                ),
              ),
              for (final opt in options)
                ListTile(
                  leading: Icon(opt.$3, color: ctx.appPrimaryLight),
                  title: Text(
                    opt.$2,
                    style: TextStyle(color: ctx.appTextPrimary),
                  ),
                  trailing: opt.$1 == current
                      ? Icon(Icons.check, color: ctx.appPrimary)
                      : null,
                  onTap: () => Navigator.pop(ctx, opt.$1),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      await ref.read(themeModeProvider.notifier).setThemeMode(selected);
    }
  }

  static Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appCard,
        title: Text(s.logoutConfirmTitle),
        content: Text(s.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: Text(s.logout),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authSessionProvider.notifier).logout();
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.phone,
    required this.email,
    required this.roleLabel,
  });

  final String name;
  final String phone;
  final String email;
  final String roleLabel;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
    }
    return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: context.appAvatarBg,
          child: Text(
            _initials,
            style: TextStyle(
              color: context.appPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.appTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          roleLabel,
          style: TextStyle(
            color: context.appTextSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (phone.isNotEmpty || email.isNotEmpty) ...[
          const SizedBox(height: 14),
          if (phone.isNotEmpty)
            _ContactLine(icon: Icons.phone_outlined, text: phone),
          if (phone.isNotEmpty && email.isNotEmpty) const SizedBox(height: 6),
          if (email.isNotEmpty)
            _ContactLine(icon: Icons.email_outlined, text: email),
        ],
      ],
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: context.appTextSecondary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appTextSecondary,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: context.appTextSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appCard,
      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      elevation: context.isDarkTheme ? 0 : 1,
      shadowColor: AppColors.shadow,
      child: Column(children: children),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
      color: context.appDivider,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingValue,
    this.destructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingValue;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? const Color(0xFFC62828) : context.appTextPrimary;
    final iconColor =
        destructive ? const Color(0xFFC62828) : context.appPrimaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailingValue != null) ...[
              Text(
                trailingValue!,
                style: TextStyle(
                  color: context.appTextSecondary,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(width: 4),
            ],
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: context.appTextSecondary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
