import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Best-effort browser push registration. In-app notifications remain the
/// authoritative channel when a browser does not support push or permission
/// is declined.
class WebPushNotificationService {
  Future<AuthorizationStatus> requestPermission() async {
    if (!kIsWeb) return AuthorizationStatus.notDetermined;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      try {
        const vapidKey = String.fromEnvironment('CREDEXA_FCM_VAPID_KEY');
        await FirebaseMessaging.instance.register(
          vapidKey: vapidKey.isEmpty ? null : vapidKey,
          serviceWorkerScriptPath: 'firebase-messaging-sw.js',
        );
      } on FirebaseException {
        // A VAPID key/service-worker configuration may be required by the
        // deployment. Permission state is still useful to the UI.
      }
    }
    return settings.authorizationStatus;
  }
}
