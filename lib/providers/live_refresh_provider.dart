import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_notification_service.dart';
import 'auth_providers.dart';
import 'home_providers.dart';
import 'notifications_providers.dart';

/// Polling plus court pour alerter vite (style messagerie).
const _liveRefreshInterval = Duration(seconds: 8);

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
  bool _refreshing = false;

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
    if (_refreshing) return;
    _refreshing = true;
    state++;

    try {
      _ref.invalidate(homeDashboardProvider);
      _ref.invalidate(parentNotificationsProvider);

      try {
        await _ref.read(homeDashboardProvider.future);
      } catch (_) {}

      final inbox = await _ref.read(parentNotificationsProvider.future);
      final ids =
          inbox.items.map((e) => e.id).where((id) => id.isNotEmpty).toSet();
      final prev = _knownIds;
      _knownIds = ids;

      if (prev != null) {
        final newcomers = ids.difference(prev);
        if (newcomers.isNotEmpty) {
          final newest = inbox.items.firstWhere(
            (e) => newcomers.contains(e.id),
            orElse: () => inbox.items.first,
          );
          final title = newest.title.isNotEmpty
              ? newest.title
              : 'Institut Kalunga';
          final body = newest.subtitle.isNotEmpty
              ? newest.subtitle
              : 'Vous avez une nouvelle notification.';

          await _ref.read(pushNotificationServiceProvider).showLocalAlert(
                title: title,
                body: body,
                onInApp: (alert) {
                  _ref.read(inAppAlertProvider.notifier).state = alert;
                },
              );
        }
      }
    } catch (_) {
      // Réseau / 429 : on réessaie au prochain tick.
    } finally {
      _refreshing = false;
    }
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
