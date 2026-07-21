// import 'dart:async';
// import 'package:app_links/app_links.dart';
// import 'package:base/core/constants/routes.dart';
// import 'package:base/core/services/logging_service.dart';
// import 'package:base/core/services/user_session_service.dart';
// import 'package:base/view/orders/order_details_page.dart';
// import 'package:flutter/material.dart';

// class DeepLinkService {
//   DeepLinkService();

//   final AppLinks _appLinks = AppLinks();

//   StreamSubscription<Uri>? _subscription;

//   Future<void> initialize() async {
//     try {
//       final initialUri = await _appLinks.getInitialLink();
//       if (initialUri != null) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _handleLink(initialUri);
//         });
//       }
//     } catch (_) {}

//     _subscription = _appLinks.uriLinkStream.listen(
//       _handleLink,
//       onError: (_) {},
//     );
//   }

//   Future<void> _handleLink(Uri uri) async {
//     try {
//       if (UserSessionService.kCachedUser != null) {
//         if (uri.path == '/payment/result') {
//           final orderId =
//               int.tryParse(uri.queryParameters['orderId'] ?? '') ?? 0;
//           if (AppRoutes.getCurrentRoute !=
//               OrderDetailsPage(id: orderId).runtimeType.toString()) {
//             AppRoutes.toOrderDetails(id: orderId)();
//           } else {
//             LoggingService.showMsg("Alreday inside");
//           }
//         }
//       }
//     } catch (e) {
//       LoggingService.showMsg("Deeplink failed cause $e");
//     }
//   }

//   Future<void> dispose() async {
//     await _subscription?.cancel();
//   }
// }
