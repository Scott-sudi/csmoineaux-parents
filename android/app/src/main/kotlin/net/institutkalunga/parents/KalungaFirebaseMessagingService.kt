package net.institutkalunga.parents

import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService

/**
 * Push FCM avec logo Institut Kalunga quand l’app est en arrière-plan / tuée.
 * En avant-plan, Flutter (MethodChannel) publie déjà la notif brandée.
 */
class KalungaFirebaseMessagingService : FlutterFirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        if (KalungaParentsApplication.isInForeground) {
            // Laisser Flutter / MainActivity gérer (évite le doublon).
            return
        }

        val title = remoteMessage.notification?.title
            ?: remoteMessage.data["title"]
            ?: "Institut Kalunga"
        val body = remoteMessage.notification?.body
            ?: remoteMessage.data["body"]
            ?: "Vous avez une nouvelle notification."

        NotificationBranding.show(applicationContext, title, body)
    }
}
