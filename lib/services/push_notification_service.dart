import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';
import '../core/network/api_service.dart';
import '../providers/auth_providers.dart';
import '../providers/dependency_providers.dart';
import '../providers/home_providers.dart';
import '../providers/notifications_providers.dart';

/// Canal Android — doit matcher MainActivity.kt (NOTIF_CHANNEL_ID).
const kParentsAlertChannelId = 'kalunga_parents_alerts_v6';
const kParentsAlertChannelName = 'Alertes Institut Kalunga';
const _kNativeAlertsChannel = 'net.institutkalunga.parents/alerts';

class InAppAlert {
  const InAppAlert({required this.title, required this.body});
  final String title;
  final String body;
}

final inAppAlertProvider = StateProvider<InAppAlert?>((ref) => null);

/// Anti-doublon FCM + polling (même alerte en < 90 s).
final Map<String, DateTime> _recentAlertKeys = {};

bool _claimAlertKey(String key) {
  final now = DateTime.now();
  _recentAlertKeys.removeWhere(
    (_, at) => now.difference(at) > const Duration(seconds: 90),
  );
  if (key.isEmpty) return true;
  if (_recentAlertKeys.containsKey(key)) return false;
  _recentAlertKeys[key] = now;
  return true;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  // Si FCM envoie déjà un bloc `notification`, Android l’affiche tout seul.
  // Pour data-only, on ne peut pas facilement appeler MethodChannel ici.
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
      final dedupe = message.data['source_id']?.toString() ??
          '${title}|$body|${message.messageId ?? ''}';
      // En foreground FCM affiche rarement la notif système → on la publie.
      // Dédoublonnage évite le 2e coup du live-refresh.
      await showLocalAlert(
        title: title,
        body: body,
        dedupeKey: dedupe,
        showInAppBanner: false,
      );
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

  /// Une seule notification système (style WhatsApp).
  /// [showInAppBanner] : uniquement pour le bouton « Tester » (sinon doublon).
  Future<bool> showLocalAlert({
    required String title,
    required String body,
    void Function(InAppAlert alert)? onInApp,
    String? dedupeKey,
    bool showInAppBanner = false,
  }) async {
    if (kIsWeb) return false;
    if (!_ready) await init();

    final key = (dedupeKey ?? '$title|$body').trim();
    if (!_claimAlertKey(key)) return false;

    if (showInAppBanner) {
      final alert = InAppAlert(title: title, body: body);
      onInApp?.call(alert);
    }

    // 1) Chemin natif Android (le plus fiable).
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await Permission.notification.request();
        const channel = MethodChannel(_kNativeAlertsChannel);
        await channel.invokeMethod<void>('ensureChannel');
        final posted = await channel.invokeMethod<bool>('showAlert', {
          'title': title,
          'body': body,
        });
        if (posted == true) return true;
      } catch (_) {}
    }

    // 2) Repli Flutter plugins.
    await _playAlertTone();
    try {
      await _postSystemNotification(title: title, body: body);
      return true;
    } catch (_) {
      try {
        await _postSystemNotification(
          title: title,
          body: body,
          icon: '@mipmap/ic_launcher',
        );
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> areSystemNotificationsEnabled() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      const channel = MethodChannel(_kNativeAlertsChannel);
      return await channel.invokeMethod<bool>('areNotificationsEnabled') ??
          false;
    } catch (_) {
      return false;
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
