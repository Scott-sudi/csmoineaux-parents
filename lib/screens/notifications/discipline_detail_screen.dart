import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme_colors.dart';
import '../../models/notification_detail_models.dart';
import '../../providers/dependency_providers.dart';
import '../../providers/home_providers.dart';
import '../../providers/notifications_providers.dart';

/// Détail discipline (convocation / incident).
class DisciplineDetailScreen extends ConsumerStatefulWidget {
  const DisciplineDetailScreen({
    super.key,
    required this.kind,
    required this.publicId,
  });

  final String kind;
  final String publicId;

  @override
  ConsumerState<DisciplineDetailScreen> createState() =>
      _DisciplineDetailScreenState();
}

class _DisciplineDetailScreenState
    extends ConsumerState<DisciplineDetailScreen> {
  late final Future<DisciplineDetail> _future;
  var _refreshed = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(notificationDetailServiceProvider).fetchDiscipline(
          kind: widget.kind,
          publicId: widget.publicId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(widget.kind == 'summons' ? 'Convocation' : 'Incident'),
        backgroundColor: context.appCard,
        foregroundColor: context.appTextPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<DisciplineDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(color: context.appPrimary),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error?.toString() ?? 'Impossible de charger le détail.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final d = snapshot.data!;
          if (!_refreshed) {
            _refreshed = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.invalidate(parentNotificationsProvider);
              ref.invalidate(homeDashboardProvider);
            });
          }

          final rows = <(String, String)>[
            if (d.studentName.isNotEmpty) ('Élève', d.studentName),
            if (d.dateLabel.isNotEmpty) ('Date', d.dateLabel),
            if (d.timeLabel.isNotEmpty) ('Heure', d.timeLabel),
            if (d.location.isNotEmpty) ('Lieu', d.location),
            if (d.reason.isNotEmpty) ('Motif', d.reason),
            if (d.severityLabel.isNotEmpty) ('Gravité', d.severityLabel),
            if (d.categoryLabel.isNotEmpty) ('Catégorie', d.categoryLabel),
            if (d.statusLabel.isNotEmpty) ('Statut', d.statusLabel),
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                d.title,
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              for (final row in rows) ...[
                Text(
                  row.$1,
                  style: TextStyle(
                    color: context.appTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.$2,
                  style: TextStyle(
                    color: context.appTextPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (d.content.isNotEmpty) ...[
                Text(
                  'Détails',
                  style: TextStyle(
                    color: context.appTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.appDivider),
                  ),
                  child: Text(
                    d.content,
                    style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
