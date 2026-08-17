// Généré à partir de android/app/google-services.json (projet CS Moineaux).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web non configuré pour cette app.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('Firebase iOS non configuré pour cette app.');
      default:
        throw UnsupportedError(
          'Firebase non supporté sur ${defaultTargetPlatform.name}.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZ-pNXnln777ANSzihTz8Nm7_Qy45MDVs',
    appId: '1:15023943461:android:1c1c008d9cca0d471a74cc',
    messagingSenderId: '15023943461',
    projectId: 'cs-moineaux',
    storageBucket: 'cs-moineaux.firebasestorage.app',
  );
}
