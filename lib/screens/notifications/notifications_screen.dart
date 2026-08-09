import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../models/notification_models.dart';
import '../../providers/notifications_providers.dart';
import '../../providers/settings_providers.dart';

/// Onglet Notifications — maquette : filtres Toutes / Générales / Scolaires / Financières.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _filterKeys = ['toutes', 'generales', 'scolaires', 'financieres'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _filterKeys.length, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<({String key, String label})> _filters(WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return [
      (key: 'toutes', label: s.filterAll),
      (key: 'generales', label: s.filterGeneral),
      (key: 'scolaires', label: s.filterSchool),
      (key: 'financieres', label: s.filterFinance),
    ];
  }

  List<ParentNotificationItem> _filtered(
    List<ParentNotificationItem> items,
    String key,
  ) {
    if (key == 'toutes') return items;
    return items.where((e) => e.filterBucket == key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(parentNotificationsProvider);
    final s = ref.watch(appStringsProvider);
    final filters = _filters(ref);
    final currentKey = filters[_tabs.index].key;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appCard,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          s.notificationsTitle,
          style: TextStyle(
            color: context.appTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: s.languageMenu,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.advancedFiltersSoon)),
              );
            },
            icon: Icon(Icons.filter_list, color: context.appTextPrimary),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: context.appCard,
              border: Border(
                bottom: BorderSide(color: context.appDivider, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: context.appPrimary,
              unselectedLabelColor: context.appTextSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              indicatorColor: context.appPrimary,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              tabs: [for (final f in filters) Tab(text: f.label)],
            ),
          ),
        ),
      ),
      body: asyncData.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.appPrimary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(parentNotificationsProvider),
                  child: Text(s.retry),
                ),
              ],
            ),
          ),
        ),
        data: (result) {
          final items = _filtered(result.items, currentKey);
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  result.items.isEmpty
                      ? s.noNotifications
                      : s.noNotificationsIn(filters[_tabs.index].label),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.appTextSecondary),
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(parentNotificationsProvider);
              await ref.read(parentNotificationsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _NotificationCard(item: items[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final ParentNotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appCard,
      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      elevation: context.isDarkTheme ? 0 : 1,
      shadowColor: AppColors.shadow,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: context.appTextPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: context.appTextSecondary,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.timestampLabel,
                      style: TextStyle(
                        color: context.appTextSecondary.withOpacity(0.85),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: item.isRead
                    ? Icon(
                        Icons.chevron_right,
                        color: context.appTextSecondary,
                        size: 22,
                      )
                    : Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: context.appPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
