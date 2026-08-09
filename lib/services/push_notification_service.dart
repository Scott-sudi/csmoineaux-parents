import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
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

/// Nouveau canal à chaque changement de son / importance
/// (Android verrouille le canal après la 1re création).
const kParentsAlertChannelId = 'kalunga_parents_alerts_v3';
const kParentsAlertChannelName = 'Alertes Institut Kalunga';

/// Contenu pour la bannière en haut d’écran (style WhatsApp).
class InAppAlert {
  const InAppAlert({required this.title, required this.body});
  final String title;
  final String body;
}

/// Bannière flottante affichée dans l’app (en plus de la notif système).
final inAppAlertProvider = StateProvider<InAppAlert?>((ref) => null);

/// Handler push reçu app en arrière-plan / tuée (isolate dédié).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

/// Notifications locales (son + bannière) + push FCM.
class PushNotificationService {
  PushNotificationService({required ApiService api}) : _api = api;

  final ApiService _api;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _player = AudioPlayer();

  bool _ready = false;
  bool _fcmReady = false;

  Future<void> init() async {
    if (_ready || kIsWeb) return;

    // Icône barre de statut : silhouette blanche (requis Android).
    const androidInit = AndroidInitializationSettings('@drawable/ic_stat_notify');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final vibration = Int64List.fromList([0, 400, 200, 400]);

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        kParentsAlertChannelId,
        kParentsAlertChannelName,
        description: 'Alertes sonores et bannières de l’Institut Kalunga',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('kalunga_alert'),
        enableVibration: true,
        vibrationPattern: vibration,
        showBadge: true,
        enableLights: true,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _local.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1.0);
    } catch (_) {}

    _ready = true;
    await _initFirebaseMessaging();
  }

  Future<void> _initFirebaseMessaging() async {
    if (kIsWeb || _fcmReady) return;
    try {
      await Firebase.initializeApp();
    } catch (_) {
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

  Future<void> _playAlertTone() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/kalunga_alert.wav'));
    } catch (_) {}
  }

  /// Son + bannière système (tête d’écran) + bannière in-app.
  Future<void> showLocalAlert({
    required String title,
    required String body,
    void Function(InAppAlert alert)? onInApp,
  }) async {
    if (kIsWeb) return;
    if (!_ready) await init();

    // 1) Son garanti (même si le canal Android est muet / OEM bizarre).
    await _playAlertTone();

    final vibration = Int64List.fromList([0, 400, 200, 400]);

    final androidDetails = AndroidNotificationDetails(
      kParentsAlertChannelId,
      kParentsAlertChannelName,
      channelDescription: 'Alertes sonores et bannières de l’Institut Kalunga',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('kalunga_alert'),
      enableVibration: true,
      vibrationPattern: vibration,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ticker: 'Alerte Institut Kalunga',
      fullScreenIntent: false,
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      icon: '@drawable/ic_stat_notify',
      channelShowBadge: true,
      onlyAlertOnce: false,
      silent: false,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    try {
      await _local.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
      );
    } catch (_) {}

    onInApp?.call(InAppAlert(title: title, body: body));
  }

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

    try {
      FirebaseMessaging.onMessageOpenedApp.listen((_) {
        ref.invalidate(homeDashboardProvider);
        ref.invalidate(parentNotificationsProvider);
      });
    } catch (_) {}
  });
});
