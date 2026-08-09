# Notifications push — Institut Kalunga Parents

## Deux niveaux (important)

| Situation | Son / bannière | Déjà prêt ? |
|-----------|----------------|-------------|
| **App ouverte** (APK Android / iPhone) | Oui — notification locale + tonalité | **Oui** (`flutter_local_notifications` + refresh ~25 s) |
| **App fermée / écran verrouillé** | Push FCM (comme WhatsApp) | **Code prêt** — il reste Firebase + clé serveur |

Sur **Edge / navigateur**, pas de push système : seulement le badge après refresh.

## Pour le push app fermée (à faire une fois)

### A. Firebase (toi)
1. https://console.firebase.google.com → projet « Institut Kalunga »
2. Ajouter app **Android** : `net.institutkalunga.parents`
3. Télécharger `google-services.json` →  
   `mobile/kalunga_parents/android/app/google-services.json`
4. (Plus tard iOS) app iOS même Bundle ID + `GoogleService-Info.plist` → `ios/Runner/`
5. Cloud Messaging → **Clé serveur (Server key)**

### B. Serveur o2switch
Dans `.env` :
```
FCM_SERVER_KEY=ta_cle_serveur
```
Puis redémarrer Passenger (`touch tmp/restart.txt`).

### C. Rebuild APK
```bash
cd mobile/kalunga_parents
flutter build apk --release
```

Sans `google-services.json` / `FCM_SERVER_KEY`, l’APK marche toujours :
présences, messages, badge — et **son si l’app est ouverte**.
Seuls les push « téléphone éteint / app tuée » manquent.

## Bibliothèques déjà ajoutées
- `flutter_local_notifications` (son app ouverte)
- `firebase_core` + `firebase_messaging` (push distant)
- Backend : envoi FCM avec `"sound": "default"` + canal `kalunga_parents_alerts_v2`
