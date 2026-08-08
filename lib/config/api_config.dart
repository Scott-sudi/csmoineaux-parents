/// Configuration centralisée des URLs API Django.
///
/// Ne jamais hardcoder d'URL dans les écrans ou widgets.
/// Modifier [environment] pour basculer entre production et développement.
library;

import 'package:flutter/foundation.dart';

/// Environnement d'exécution de l'API.
enum ApiEnvironment {
  /// Domaine officiel HTTPS (DNS / SSL requis).
  production,

  /// URL temporaire o2switch tant que le DNS public n'est pas propagé.
  development,
}

/// Point d'entrée unique pour l'adresse de l'API REST Kalunga.
abstract final class ApiConfig {
  /// Environnement actif.
  ///
  /// DNS public `institut-kalunga.net` non propagé : on utilise l'URL
  /// temporaire o2switch tant qu'elle reste le seul accès fonctionnel.
  /// Remettre [ApiEnvironment.production] dès que le domaine officiel répond.
  static const ApiEnvironment environment = ApiEnvironment.development;

  /// Domaine public officiel.
  static const String productionHost = 'https://institut-kalunga.net';

  /// Hôte temporaire o2switch (HTTP) — utile uniquement en phase DNS.
  static const String developmentHost =
      'http://institut-kalunga.net.susc3383.odns.fr';

  /// Proxy local anti-CORS pour Flutter Web (`tool/dev_cors_proxy.py`).
  static const String webDevProxyHost = 'http://127.0.0.1:8788';

  /// Préfixe versionné de l'API Django.
  static const String apiPrefix = '/api/v1';

  /// Hôte selon l'environnement (sans slash final).
  static String get host {
    switch (environment) {
      case ApiEnvironment.production:
        return productionHost;
      case ApiEnvironment.development:
        // Edge/Chrome bloquent les appels cross-origin vers o2switch tant que
        // CORS n'est pas déployé sur le serveur → proxy local sur le web.
        if (kIsWeb) return webDevProxyHost;
        return developmentHost;
    }
  }

  /// Base URL complète de l'API (ex. `https://…/api/v1`).
  static String get baseUrl => '$host$apiPrefix';

  /// Réécrit les URLs média pour Flutter Web (CORS via proxy local).
  static String? resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    if (!kIsWeb || environment != ApiEnvironment.development) {
      return url;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return url;
    final host = uri.host.toLowerCase();
    final isKalungaHost = host.contains('institut-kalunga') ||
        host.contains('odns.fr') ||
        host == Uri.parse(developmentHost).host;
    if (!isKalungaHost) return url;
    return Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: 8788,
      path: uri.path,
      query: uri.hasQuery ? uri.query : null,
    ).toString();
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
