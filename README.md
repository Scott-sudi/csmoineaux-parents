# Kalunga Parents (Flutter)

Application mobile officielle des **parents** de l’Institut Kalunga.

Elle consomme uniquement l’API REST Django déjà déployée — aucune base de données locale métier.

## API

| Élément | Valeur |
|--------|--------|
| Domaine production | `https://institut-kalunga.net` |
| Préfixe API | `/api/v1` |
| Config centralisée | `lib/config/api_config.dart` |

Ne jamais mettre d’URL dans les écrans. Pour basculer vers l’URL temporaire o2switch (DNS non propagé), modifier `ApiConfig.environment`.

## Architecture

```
lib/
  config/          # ApiConfig
  constants/       # Endpoints, constantes UI
  core/            # Dio, exceptions, thème, secure storage
  models/
  services/        # Auth, Login, User, Home
  repositories/
  providers/       # Riverpod
  screens/
  widgets/
  utils/
  main.dart
```

## Première étape livrée

- Page **Accueil** fidèle à la maquette (vue d’ensemble + activités + bottom nav 5 onglets)
- **Connexion téléphone** au démarrage (`AuthGate` → `LoginPhoneScreen`)
- API Django `POST /api/v1/parents/auth/verify-phone/` (responsable / Guardian)
- Architecture auth extensible (`AuthChallenge` : phone → password / PIN / OTP / biométrie)
- Couche réseau Dio + enveloppe JSON Kalunga
- Auth JWT + `flutter_secure_storage` (JWT pour plus tard ; session téléphone active)
- Données Accueil en **mock** (`HomeService.useMockData = true`), prêtes à être remplacées par l’API

## Lancer le projet

Un SDK Flutter local est disponible sous `IK/tools/flutter` (non versionné).

Dans PowerShell / CMD :

```bat
cd kalunga-school\mobile\kalunga_parents
..\..\..\tools\flutter\bin\flutter.bat pub get
..\..\..\tools\flutter\bin\flutter.bat run -d chrome
```

Ou avec un Flutter déjà dans le PATH :

```bash
cd mobile/kalunga_parents
flutter pub get
flutter run
```

> L’installation Puro (`~/.puro/envs/stable`) était corrompue sur cette machine ; le SDK sous `tools/flutter` sert de contournement.