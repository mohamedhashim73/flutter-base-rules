part of 'services.dart';

// import 'dart:async';
// import 'dart:convert';
// import 'package:base/core/constants/constants.dart';
// import 'package:base/core/constants/extensions/models_extensions.dart';
// import 'package:base/core/constants/routes.dart';
// import 'package:base/core/services/local_notifications_service.dart';
// import 'package:base/core/services/logging_service.dart';
// import 'package:base/firebase_options.dart';
// import 'package:base/model/notify_payload_model.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   LoggingService.showMsg(
//     "============ onMessageBackground | Title ${message.notification?.title} , Body ${message.notification?.body} | Data ${message.data} ============",
//   );
// }

// class NotificationsService {
//   static Map<String, dynamic>? _pendingTerminatedPayload;
//   static void consumePendingTerminatedPayload() {
//     if (_pendingTerminatedPayload == null) {
//       return;
//     }

//     final payload = _pendingTerminatedPayload!;
//     _pendingTerminatedPayload = null;

//     int attempts = 0;
//     Timer.periodic(const Duration(milliseconds: 300), (timer) {
//       attempts++;
//       if (AppRoutes.key.currentState != null) {
//         timer.cancel();
//         handleTapRoute(payload);
//       } else if (attempts >= 15) {
//         timer.cancel();
//       }
//     });
//   }

//   static Future<void> initialize() async {
//     try {
//       await Firebase.initializeApp(
//         options: DefaultFirebaseOptions.currentPlatform,
//       );
//       await requestPermission();
//       await LocalNotificationService.init();
//       FirebaseMessaging.onBackgroundMessage(
//         _firebaseMessagingBackgroundHandler,
//       );
//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         LoggingService.showMsg(
//           "============ onMessage | Title ${message.notification?.title} , Body ${message.notification?.body} | Data ${message.data} ============",
//         );
//         final notification = message.notification;
//         if (notification != null) {
//           LocalNotificationService.showImmediatelyNotify(
//             title: notification.title,
//             body: notification.body ?? '',
//             payload: jsonEncode(message.data),
//           );
//         }
//       });
//       FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//         LoggingService.showMsg(
//           "============ onMessageOpenedApp | Title ${message.notification?.title} , Body ${message.notification?.body} | Data ${message.data} ============",
//         );
//         handleTapRoute(message.data);
//       });
//       final RemoteMessage? initialMessage = await FirebaseMessaging.instance
//           .getInitialMessage();
//       if (initialMessage != null) {
//         _pendingTerminatedPayload = initialMessage.data;
//       }
//       LoggingService.showMsg("User's FCM : ${await getFCMToken()}");
//     } catch (e) {
//       LoggingService.showMsg(e.toString());
//     }
//   }

//   static Future<void> getAPNSToken() async {
//     try {
//       if (AppConstants.kPlatformIsIOS) {
//         await FirebaseMessaging.instance.getAPNSToken();
//       }
//     } catch (e) {
//       LoggingService.showMsg(e.toString());
//     }
//   }

//   static String? _fcmToken;
//   static Future<String?> getFCMToken() async {
//     try {
//       if (_fcmToken != null) return _fcmToken;
//       await getAPNSToken();
//       _fcmToken = await FirebaseMessaging.instance.getToken();
//       return _fcmToken;
//     } catch (e) {
//       LoggingService.showMsg(e.toString());
//       return null;
//     }
//   }

//   static Future<void> requestPermission() async {
//     await FirebaseMessaging.instance.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//   }

//   static void handleTapRoute(dynamic payload) {
//     try {
//       NotificationPayloadModel notify = NotificationPayloadModel.fromJson(
//         payload,
//       );
//       notify.onTap();
//     } catch (e) {
//       LoggingService.showMsg("Error: $e");
//     }
//   }
// }
