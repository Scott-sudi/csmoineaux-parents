import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_models.dart';
import 'auth_providers.dart';
import 'dependency_providers.dart';

/// Charge le tableau de bord Accueil (API Django) et synchronise le nom.
///
/// Se recharge dès que la session parent change (login / logout / nom).
final homeDashboardProvider =
    FutureProvider.autoDispose<HomeDashboard>((ref) async {
  final session = ref.watch(authSessionProvider);
  final sessionName = switch (session) {
    AuthSessionAuthenticated(:final identity) => identity.displayName,
    _ => '',
  };

  final repo = ref.watch(homeRepositoryProvider);
  final dashboard = await repo.loadDashboard();

  final liveName = dashboard.parentDisplayName.trim();
  // Met à jour la session mémoire (Mon Compte + salutation) si le nom a changé en DB.
  if (liveName.isNotEmpty && liveName != sessionName) {
    await ref.read(authSessionProvider.notifier).syncDisplayName(liveName);
  }

  return dashboard;
});

/// Index de l'onglet actif de la barre de navigation inférieure.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
