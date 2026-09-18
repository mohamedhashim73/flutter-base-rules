part of 'services.dart';

// import 'dart:async';
// import 'dart:convert';
// import 'package:base/core/services/firebase_messaging_service.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'logging_service.dart';
// import 'dart:math';

// class LocalNotificationService {
//   static final FlutterLocalNotificationsPlugin
//   _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//   static Future<void> checkPermissions() async {
//     final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
//         _flutterLocalNotificationsPlugin
//             .resolvePlatformSpecificImplementation<
//               AndroidFlutterLocalNotificationsPlugin
//             >();
//     final bool? granted = await androidImplementation
//         ?.areNotificationsEnabled();
//     if (granted == null || !granted) {
//       await Permission.notification.request();
//     }
//   }

//   static final DarwinInitializationSettings _darwinInitializationSettings =
//       DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestBadgePermission: true,
//         requestSoundPermission: true,
//       );

//   static final AndroidInitializationSettings _androidInitializationSettings =
//       const AndroidInitializationSettings('@mipmap/ic_launcher');

//   static AndroidNotificationDetails _defaultAndroidNotificationDetails(
//     String? bigText,
//   ) => AndroidNotificationDetails(
//     'instant_notifications',
//     'إشعارات فورية',
//     importance: Importance.max,
//     styleInformation: bigText != null ? BigTextStyleInformation(bigText) : null,
//     priority: Priority.high,
//   );

//   static final DarwinNotificationDetails _defaultDarwinNotificationDetails =
//       const DarwinNotificationDetails();

//   static Future init() async {
//     await checkPermissions();
//     InitializationSettings settings = InitializationSettings(
//       android: _androidInitializationSettings,
//       iOS: _darwinInitializationSettings,
//     );
//     await _flutterLocalNotificationsPlugin.initialize(
//       settings,
//       onDidReceiveNotificationResponse: (NotificationResponse details) {
//         if (details.payload != null) {
//           try {
//             NotificationsService.handleTapRoute(jsonDecode(details.payload!));
//           } catch (e) {
//             LoggingService.showMsg("Payload decode error: $e");
//           }
//         }
//       },
//     );
//   }

//   static Future<void> showImmediatelyNotify({
//     required String body,
//     String? title,
//     String? payload,
//   }) async {
//     await _flutterLocalNotificationsPlugin.show(
//       Random().nextInt(1000),
//       title,
//       body,
//       payload: payload,
//       NotificationDetails(
//         android: _defaultAndroidNotificationDetails(body),
//         iOS: _defaultDarwinNotificationDetails,
//       ),
//     );
//   }

//   static Future<void> cancelNotify(int id) async {
//     try {
//       await _flutterLocalNotificationsPlugin.cancel(id);
//     } catch (e) {
//       LoggingService.showMsg("Ex: $e");
//     }
//   }

//   static Future<void> cancelAllNotifications() async {
//     try {
//       await _flutterLocalNotificationsPlugin.cancelAll();
//     } catch (e) {
//       LoggingService.showMsg("Ex: $e");
//     }
//   }
// }
