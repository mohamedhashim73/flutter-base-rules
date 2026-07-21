import 'dart:io';
import 'package:base/core/services/dependency_injection.dart';
import 'package:base/core/services/base/system_ui_service.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppConstants {
  static const String kSupportPhone = "+201099874902";
  static const String kGooglePlayStoreID = "com.dev3solutions.beeto.app";
  static const String kAppStoreID = "id6782384506";
  static const String kMainFont = "GraphikArabic";
  static const double kBorderWidth = 1;
  static const double kLoadingBlurSigma = 2;
  static Future<void> kAppInitialization() async {
    await Future.value([
      await DI.init(),
      await SystemUiService.enableEdgeToEdge(),
      // await NotificationsService.initialize(),
      // sl<DeepLinkService>().initialize(),
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
  static BorderRadius kMainRadius = BorderRadius.circular(10);
  static BorderRadius kMaxRadius = BorderRadius.circular(22);
  static BoxBorder kMainBorder = Border.all(
    color: AppColors.kSoftGrey,
    width: kBorderWidth,
  );
  static BoxBorder kSkeletonLoadingBorder = Border.all(
    color: const Color(0xff2684FF).withValues(alpha: 0.04),
    width: kBorderWidth,
  );
}
