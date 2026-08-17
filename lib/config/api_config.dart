/// Configuration centralisée des URLs API Django.
///
/// Ne jamais hardcoder d'URL dans les écrans ou widgets.
/// Pour basculer LOCAL → nouvelle production, changez uniquement [environment]
/// (et éventuellement [productionHost] le jour du nouvel hébergement).
library;

import 'package:flutter/foundation.dart';

/// Environnement d'exécution de l'API.
enum ApiEnvironment {
  /// Django sur cette machine (aucune connexion à l'ancien serveur).
  local,

  /// Nouvelle API de production — à renseigner plus tard.
  production,
}

/// Point d'entrée unique pour l'adresse de l'API REST.
abstract final class ApiConfig {
  /// Environnement actif.
  ///
  /// Passez à [ApiEnvironment.production] uniquement quand la nouvelle
  /// API hébergée sera prête. Ne jamais remettre l'ancien domaine Kalunga.
  static const ApiEnvironment environment = ApiEnvironment.production;

  /// Surcharge optionnelle : `flutter run --dart-define=API_HOST=http://192.168.1.71:8000`
  static const String apiHostOverride = String.fromEnvironment('API_HOST');

  /// URL Django locale (sans slash final).
  ///
  /// - Navigateur / Windows : 127.0.0.1
  /// - Émulateur Android : 10.0.2.2
  /// - Téléphone sur le même Wi-Fi : IP LAN du PC
  static const String localLoopbackHost = 'http://127.0.0.1:8000';
  static const String androidEmulatorHost = 'http://10.0.2.2:8000';
  static const String lanHost = 'http://192.168.1.71:8000';

  /// Production Moineaux (HTTP temporaire o2switch tant que csmoineaux.com n'est pas payé).
  static const String productionHost = 'http://csmoineauxcom.susc3383.odns.fr';

  /// Préfixe versionné de l'API Django.
  static const String apiPrefix = '/api/v1';

  /// Hôte selon l'environnement (sans slash final).
  static String get host {
    if (apiHostOverride.trim().isNotEmpty) {
      return apiHostOverride.trim().replaceAll(RegExp(r'/$'), '');
    }
    switch (environment) {
      case ApiEnvironment.production:
        return productionHost;
      case ApiEnvironment.local:
        if (kIsWeb) return localLoopbackHost;
        if (defaultTargetPlatform == TargetPlatform.android) {
          return androidEmulatorHost;
        }
        return localLoopbackHost;
    }
  }

  /// Base URL complète de l'API (ex. `http://127.0.0.1:8000/api/v1`).
  static String get baseUrl => '$host$apiPrefix';

  /// Réécrit les URLs média pour Flutter Web (même hôte local).
  static String? resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    if (!kIsWeb || environment != ApiEnvironment.local) {
      return url;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return url;
    final local = Uri.parse(host);
    if (uri.host == local.host ||
        uri.host == '127.0.0.1' ||
        uri.host == 'localhost' ||
        uri.host == '10.0.2.2') {
      return url;
    }
    return url;
  }

  /// Timeouts réseau (secondes).
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// En-têtes HTTP communs.
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
