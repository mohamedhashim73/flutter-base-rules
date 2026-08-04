import 'package:base/core/widgets/custom_dialogs_widget/show_snack_bar.dart';
import 'package:base/core/enums/language_enum.dart';
import 'package:flutter/material.dart';
import 'package:base/core/routes/routes.dart';
import 'package:base/core/network/network.dart';
import 'package:base/core/services/logging_service.dart';
import 'package:base/model/user_model.dart';

class UserSessionService {
  static UserModel? get kCachedUser => CacheManager.getUser;
  static LanguageEnums get kCurrentLang => CacheManager.getLanguage();
  static bool get kIsEnglish => kCurrentLang == LanguageEnums.en;
  static Widget get kGetMainRoute =>
      kCachedUser != null ?  const SizedBox() : const SizedBox();

  static Future<void> validateSessionExpire({
    bool logOutIsOn = false,
    bool isExpired = false,
  }) async {
    try {
      if ((isExpired && kCachedUser != null) || logOutIsOn) {
        await emptyCache();
        await emptyCubits();
        AppRoutes.goToLogin.call();
        if (isExpired) {
          AppToast.showToast(
            message: "Session expired, login again",
          );
        }
      }
    } catch (e) {
      LoggingService.showMsg('ValidateSessionExpire: $e');
    }
  }

  static Future<void> emptyCache() async {
    try {
      CacheHelper.clearCache();
    } catch (e) {
      LoggingService.showMsg('Ex: $e');
    }
  }

  static Future<void> emptyCubits() async {
    try {
    } catch (e) {
      LoggingService.showMsg('Ex: $e');
    }
  }
}
