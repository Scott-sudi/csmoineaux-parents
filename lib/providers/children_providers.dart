import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/api_exception.dart';
import '../models/child_models.dart';
import 'dependency_providers.dart';

/// Liste des enfants du parent connecté.
final childrenListProvider = FutureProvider.autoDispose<List<ChildSummary>>((
  ref,
) async {
  try {
    return await ref.watch(childrenRepositoryProvider).loadChildren();
  } on ApiException catch (e) {
    // Message métier uniquement pour l'UI.
    throw ChildrenLoadException(_friendlyMessage(e));
  } catch (_) {
    throw const ChildrenLoadException(
      'Impossible de charger la liste des enfants. Réessayez.',
    );
  }
});

String _friendlyMessage(ApiException e) {
  if (e is TimeoutException) {
    return 'Le serveur met trop de temps à répondre. Réessayez.';
  }
  if (e is NetworkException) {
    return 'Impossible de joindre le serveur. Vérifiez votre connexion.';
  }
  if (e.message.trim().isNotEmpty) {
    // Messages API déjà rédigés pour l'utilisateur.
    final msg = e.message.trim();
    if (!msg.toLowerCase().contains('exception') &&
        !msg.toLowerCase().contains('traceback')) {
      return msg;
    }
  }
  return 'Une erreur est survenue. Réessayez plus tard.';
}

class ChildrenLoadException implements Exception {
  const ChildrenLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}
