import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';
import '../core/network/api_service.dart';
import '../providers/auth_providers.dart';
import '../providers/dependency_providers.dart';
import '../providers/home_providers.dart';
import '../providers/notifications_providers.dart';

/// Canal Android — nouveau id = nouveau réglage son (Android verrouille les canaux).
const kParentsAlertChannelId = 'kalunga_parents_alerts_v5';
const kParentsAlertChannelName = 'Alertes Institut Kalunga';

class InAppAlert {
  const InAppAlert({required this.title, required this.body});
  final String title;
  final String body;
}

final inAppAlertProvider = StateProvider<InAppAlert?>((ref) => null);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

/// Publie de VRAIES notifications système Android (son + bannière).
class PushNotificationService {
  PushNotificationService({required ApiService api}) : _api = api;

  final ApiService _api;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _player = AudioPlayer();

  bool _ready = false;
  bool _fcmReady = false;
  bool _audioConfigured = false;

  Future<void> init() async {
    if (_ready || kIsWeb) return;

    const androidInit =
        AndroidInitializationSettings('@drawable/ic_stat_notify');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final vibration = Int64List.fromList([0, 500, 200, 500, 200, 500]);

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        kParentsAlertChannelId,
        kParentsAlertChannelName,
        description: 'Messages école, présences, finances — avec son',
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

    await _configureAudio();
    _ready = true;
    await _initFirebaseMessaging();
  }

  Future<void> _configureAudio() async {
    if (_audioConfigured) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await AudioPlayer.global.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: true,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.notificationRingtone,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
          ),
        );
      }
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1.0);
      _audioConfigured = true;
    } catch (_) {}
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
    await _configureAudio();
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/kalunga_alert.wav'), volume: 1.0);
    } catch (_) {}
    try {
      await HapticFeedback.heavyImpact();
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  Future<void> _postSystemNotification({
    required String title,
    required String body,
    String? icon,
  }) async {
    final vibration = Int64List.fromList([0, 500, 200, 500, 200, 500]);
    final androidDetails = AndroidNotificationDetails(
      kParentsAlertChannelId,
      kParentsAlertChannelName,
      channelDescription: 'Messages école, présences, finances — avec son',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('kalunga_alert'),
      enableVibration: true,
      vibrationPattern: vibration,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      ticker: 'Alerte Institut Kalunga',
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      icon: icon ?? '@drawable/ic_stat_notify',
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

    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  /// Vraie notif Android (barre + son) + bannière in-app + tonalité.
  Future<void> showLocalAlert({
    required String title,
    required String body,
    void Function(InAppAlert alert)? onInApp,
  }) async {
    if (kIsWeb) return;
    if (!_ready) await init();

    onInApp?.call(InAppAlert(title: title, body: body));
    await _playAlertTone();

    try {
      await _postSystemNotification(title: title, body: body);
    } catch (_) {
      // Repli icône launcher si drawable custom échoue.
      try {
        await _postSystemNotification(
          title: title,
          body: body,
          icon: '@mipmap/ic_launcher',
        );
      } catch (_) {}
    }
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
