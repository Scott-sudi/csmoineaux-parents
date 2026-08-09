import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';
import '../core/network/api_service.dart';
import '../providers/auth_providers.dart';
import '../providers/dependency_providers.dart';
import '../providers/home_providers.dart';
import '../providers/notifications_providers.dart';

/// Canal Android — nouveau id pour forcer son + vibration
/// (Android verrouille les réglages d’un canal après création).
const kParentsAlertChannelId = 'kalunga_parents_alerts_v2';
const kParentsAlertChannelName = 'Institut Kalunga';

/// Handler push reçu app en arrière-plan / tuée (isolate dédié).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

/// Notifications locales (son) + push FCM (app ouverte / fermée).
///
/// - **App ouverte (APK)** : son via notification locale (refresh 25s + FCM foreground).
/// - **App fermée** : FCM + `google-services.json` + `FCM_SERVER_KEY` serveur.
/// - **Web** : pas de push système.
class PushNotificationService {
  PushNotificationService({required ApiService api}) : _api = api;

  final ApiService _api;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool _fcmReady = false;

  Future<void> init() async {
    if (_ready || kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kParentsAlertChannelId,
        kParentsAlertChannelName,
        description: 'Messages, présences et alertes de l’Institut Kalunga',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _local.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    _ready = true;
    await _initFirebaseMessaging();
  }

  Future<void> _initFirebaseMessaging() async {
    if (kIsWeb || _fcmReady) return;
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Pas de google-services.json / Firebase → push distant indisponible.
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // iOS : afficher aussi en foreground.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ??
          message.data['title']?.toString() ??
          'Institut Kalunga';
      final body = message.notification?.body ??
          message.data['body']?.toString() ??
          'Vous avez une nouvelle notification.';
      await showLocalAlert(title: title, body: body);
    });

    _fcmReady = true;
  }

  /// Affiche une notification système avec son (tonalité appareil).
  Future<void> showLocalAlert({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (!_ready) await init();

    const androidDetails = AndroidNotificationDetails(
      kParentsAlertChannelId,
      kParentsAlertChannelName,
      channelDescription: 'Messages, présences et alertes de l’Institut Kalunga',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      ticker: 'Nouvelle notification Institut Kalunga',
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  /// Récupère le token FCM et l’enregistre côté Django.
  Future<void> syncDeviceToken(String guardianPublicId) async {
    if (kIsWeb || guardianPublicId.isEmpty) return;
    if (!_ready) await init();
    if (!_fcmReady) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await registerDeviceToken(
        guardianPublicId: guardianPublicId,
        token: token,
      );

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        registerDeviceToken(
          guardianPublicId: guardianPublicId,
          token: newToken,
        );
      });
    } catch (_) {}
  }

  Future<void> registerDeviceToken({
    required String guardianPublicId,
    required String token,
    String? platform,
  }) async {
    if (guardianPublicId.isEmpty || token.isEmpty) return;
    final plat = platform ??
        (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
    try {
      await _api.post<Map<String, dynamic>>(
        ApiEndpoints.parentDeviceRegister,
        data: {
          'guardian_public_id': guardianPublicId,
          'token': token,
          'platform': plat,
        },
        parser: (raw) => Map<String, dynamic>.from(raw as Map? ?? const {}),
      );
    } catch (_) {}
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(api: ref.watch(apiServiceProvider));
});

/// Initialise canal + FCM après connexion (mobile uniquement).
final pushBootstrapProvider = Provider<void>((ref) {
  ref.listen<AuthSessionState>(authSessionProvider, (prev, next) async {
    if (next is! AuthSessionAuthenticated) return;
    if (kIsWeb) return;
    final push = ref.read(pushNotificationServiceProvider);
    await push.init();
    await push.syncDeviceToken(next.identity.guardianPublicId);

    // Si l’utilisateur ouvre l’app via une notif, rafraîchir l’inbox.
    try {
      FirebaseMessaging.onMessageOpenedApp.listen((_) {
        ref.invalidate(homeDashboardProvider);
        ref.invalidate(parentNotificationsProvider);
      });
    } catch (_) {}
  });
});
