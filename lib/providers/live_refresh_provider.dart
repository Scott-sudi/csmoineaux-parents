import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_notification_service.dart';
import 'auth_providers.dart';
import 'home_providers.dart';
import 'notifications_providers.dart';

/// Intervalle d'actualisation automatique (style messagerie).
const _liveRefreshInterval = Duration(seconds: 25);

/// Garde Accueil + Notifications à jour sans pull-to-refresh.
class LiveRefreshController extends StateNotifier<int>
    with WidgetsBindingObserver {
  LiveRefreshController(this._ref) : super(0) {
    WidgetsBinding.instance.addObserver(this);
    _syncWithAuth(_ref.read(authSessionProvider));
    _authSub = _ref.listen<AuthSessionState>(authSessionProvider, (_, next) {
      _syncWithAuth(next);
    });
  }

  final Ref _ref;
  Timer? _timer;
  ProviderSubscription<AuthSessionState>? _authSub;
  Set<String>? _knownIds;

  void _syncWithAuth(AuthSessionState session) {
    if (session is AuthSessionAuthenticated) {
      _start();
      unawaited(refreshNow());
    } else {
      _stop();
      _knownIds = null;
    }
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(_liveRefreshInterval, (_) {
      unawaited(refreshNow());
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refreshNow() async {
    if (_ref.read(authSessionProvider) is! AuthSessionAuthenticated) return;

    _ref.invalidate(homeDashboardProvider);
    _ref.invalidate(parentNotificationsProvider);
    state++;

    try {
      await _ref.read(homeDashboardProvider.future);
      final inbox = await _ref.read(parentNotificationsProvider.future);
      final ids = inbox.items.map((e) => e.id).where((id) => id.isNotEmpty).toSet();
      final prev = _knownIds;
      _knownIds = ids;

      // Son dès qu’un nouvel item apparaît (même déjà « lu » côté API,
      // ex. paiement / incident) — pas seulement si le badge augmente.
      if (prev != null) {
        final newcomers = ids.difference(prev);
        if (newcomers.isNotEmpty) {
          final newest = inbox.items.firstWhere(
            (e) => newcomers.contains(e.id),
            orElse: () => inbox.items.first,
          );
          await _ref.read(pushNotificationServiceProvider).showLocalAlert(
                title: newest.title.isNotEmpty
                    ? newest.title
                    : 'Institut Kalunga',
                body: newest.subtitle.isNotEmpty
                    ? newest.subtitle
                    : 'Vous avez une nouvelle notification.',
              );
        }
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      unawaited(refreshNow());
      _start();
    }
  }

  void tearDown() {
    _stop();
    _authSub?.close();
    WidgetsBinding.instance.removeObserver(this);
  }
}

final liveRefreshProvider =
    StateNotifierProvider<LiveRefreshController, int>((ref) {
  final controller = LiveRefreshController(ref);
  ref.onDispose(controller.tearDown);
  return controller;
});
