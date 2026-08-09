import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_notification_service.dart';
import 'auth_providers.dart';
import 'home_providers.dart';
import 'notifications_providers.dart';

const _liveRefreshInterval = Duration(seconds: 5);

/// Garde Accueil + Notifications à jour et déclenche son + bannière.
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
  String? _lastTopId;
  int? _lastTotal;
  bool _refreshing = false;
  bool _baselineReady = false;

  void _syncWithAuth(AuthSessionState session) {
    if (session is AuthSessionAuthenticated) {
      _start();
      unawaited(refreshNow());
    } else {
      _stop();
      _knownIds = null;
      _lastTopId = null;
      _lastTotal = null;
      _baselineReady = false;
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

  Future<void> _fireAlert({
    required String title,
    required String body,
  }) async {
    // Bannière immédiate (même si le player échoue après).
    _ref.read(inAppAlertProvider.notifier).state =
        InAppAlert(title: title, body: body);

    await _ref.read(pushNotificationServiceProvider).showLocalAlert(
          title: title,
          body: body,
          onInApp: (alert) {
            _ref.read(inAppAlertProvider.notifier).state = alert;
          },
        );
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
      final topId = inbox.items.isNotEmpty ? inbox.items.first.id : '';
      final total = inbox.totalCount;

      final prevIds = _knownIds;
      final prevTop = _lastTopId;
      final prevTotal = _lastTotal;

      _knownIds = ids;
      _lastTopId = topId;
      _lastTotal = total;

      // 1er passage : mémoriser sans alerter.
      if (!_baselineReady || prevIds == null) {
        _baselineReady = true;
        return;
      }

      final newcomers = ids.difference(prevIds);
      final topChanged = topId.isNotEmpty && topId != prevTop;
      final countUp = total > (prevTotal ?? 0);

      if (newcomers.isEmpty && !topChanged && !countUp) return;

      final newest = inbox.items.firstWhere(
        (e) => newcomers.contains(e.id) || e.id == topId,
        orElse: () => inbox.items.isNotEmpty
            ? inbox.items.first
            : throw StateError('empty'),
      );

      await _fireAlert(
        title: newest.title.isNotEmpty ? newest.title : 'Institut Kalunga',
        body: newest.subtitle.isNotEmpty
            ? newest.subtitle
            : 'Vous avez une nouvelle notification.',
      );
    } catch (_) {
      // Réseau / 429 : prochain tick.
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
