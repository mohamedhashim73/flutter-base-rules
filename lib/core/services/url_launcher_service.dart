// import 'package:base/core/constants/constants.dart';
// import 'package:base/core/constants/enums/enums.dart';
// import 'package:base/core/localization/localization_keys.dart';
// import 'package:base/core/services/logging_service.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../components/custom_dialogs_widget/show_toast.dart';

// class UrlLauncherUtils {
//   static Future<void> openAppOnStore(
//     String googlePlayStoreID,
//     String appStoreID,
//   ) async {
//     try {
//       await launchUrl(
//         Uri.parse(
//           AppConstants.kPlatformIsIOS
//               ? "https://apps.apple.com/app/id$appStoreID"
//               : "https://play.google.com/store/apps/details?id=$googlePlayStoreID",
//         ),
//       );
//     } catch (e) {
//       LoggingService.showMsg(e);
//     }
//   }

//   static Future<void> openUrl({required String url}) async {
//     try {
//       await launchUrl(Uri.parse(url));
//     } catch (e) {
//       LoggingService.showMsg(e);
//     }
//   }

//   static Future<void> callPhone({required String phoneNumber}) async {
//     try {
//       final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
//       if (!await canLaunchUrl(phoneUri)) {
//         AppToast.showToast(
//           message: LocalizationKeys.cantOpenPhoneApp.translate,
//           type: MsgType.error,
//         );
//       }
//       await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
//     } catch (e) {
//       LoggingService.showMsg(e);
//     }
//   }

//   static Future<void> openWhatsApp({
//     required String phoneNumber,
//     String message = '',
//   }) async {
//     try {
//       final Uri whatsappUri = Uri.parse(
//         'https://wa.me/$phoneNumber${message.isNotEmpty ? '?text=${Uri.encodeComponent(message)}' : ''}',
//       );
//       await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
//     } catch (e) {
//       LoggingService.showMsg(e);
//     }
//   }
// }
