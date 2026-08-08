import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/home_models.dart';
import '../../providers/auth_providers.dart';
import '../../providers/home_providers.dart';
import '../../widgets/home/activity_item.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/overview_card.dart';

/// Page Accueil — reproduction fidèle de la maquette.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    this.onOpenNotifications,
  });

  final VoidCallback? onOpenNotifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDashboard = ref.watch(homeDashboardProvider);
    final session = ref.watch(authSessionProvider);
    final sessionName = switch (session) {
      AuthSessionAuthenticated(:final identity) => identity.displayName.trim(),
      _ => '',
    };

    return ColoredBox(
      color: AppColors.background,
      child: asyncDashboard.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(homeDashboardProvider),
        ),
        data: (dashboard) => _HomeBody(
          dashboard: dashboard,
          // Toujours le même nom que « Mon Compte » (session live).
          greetingName: sessionName.isNotEmpty
              ? sessionName
              : dashboard.parentDisplayName,
          onOpenNotifications: onOpenNotifications,
          onRefresh: () async {
            ref.invalidate(homeDashboardProvider);
            await ref.read(homeDashboardProvider.future);
          },
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.dashboard,
    required this.greetingName,
    required this.onRefresh,
    this.onOpenNotifications,
  });

  final HomeDashboard dashboard;
  final String greetingName;
  final Future<void> Function() onRefresh;
  final VoidCallback? onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: HomeHeader(
              parentName: greetingName,
              notificationCount: dashboard.overview.unreadNotificationsBadge,
              onNotificationTap: onOpenNotifications,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.pagePadding,
              4,
              AppConstants.pagePadding,
              8,
            ),
            sliver: SliverToBoxAdapter(
              child: OverviewCard(overview: dashboard.overview),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.pagePadding,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Activités récentes',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Liste complète des activités — à venir.',
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryLight,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (dashboard.activities.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppConstants.pagePadding,
                0,
                AppConstants.pagePadding,
                24,
              ),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Aucune activité récente pour le moment.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding,
                0,
                AppConstants.pagePadding,
                24,
              ),
              sliver: SliverList.separated(
                itemCount: dashboard.activities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return ActivityItem(activity: dashboard.activities[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.primary, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
