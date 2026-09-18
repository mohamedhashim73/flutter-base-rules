import 'dart:io';
import 'package:base/core/services/dependency_injection.dart';
import 'package:base/core/services/base/system_ui_service.dart';

class AppConstants {
  static const String kSupportPhone = "+201099874902";
  static const String kGooglePlayStoreID = "com.dev3solutions.beeto.app";
  static const String kAppStoreID = "id6782384506";
  static const String kMainFont = "GraphikArabic";
  static Future<void> kAppInitialization() async {
    await Future.value([
      await DI.init(),
      await SystemUiService.enableEdgeToEdge(),
    ]);
  }

  static bool get kPlatformIsIOS {
    try {
      return Platform.isMacOS || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static bool kPlatformIsAndroid = !kPlatformIsIOS;
}
