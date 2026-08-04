import 'dart:convert';
import 'package:base/core/routes/routes.dart';
import 'package:base/core/services/base/asset_service.dart';
import 'package:base/core/services/user_session_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class LocalizationService {
  final Locale? locale;
  Map<String, dynamic>? jsonData;
  LocalizationService({required this.locale});

  static LocalizationsDelegate<LocalizationService> delegate =
      _MyLocalizationsDelegates();

  static LocalizationService get getInstance {
    final context = AppRoutes.key.currentContext;
    if (context == null) {
      return LocalizationService(locale: null);
    }
    return Localizations.of<LocalizationService>(context, LocalizationService)!;
  }

  Future<void> loadJsonFile() async {
    if (jsonData != null) return;
    String jsonSource = await rootBundle.loadString(
      Assets.localizationJson,
    );
    jsonData = jsonDecode(jsonSource);
  }

  String getValue({required String key}) {
    if (jsonData == null || !jsonData!.containsKey(key)) {
      return key;
    }

    final langCode = UserSessionService.kCurrentLang.name;
    final translation = jsonData![key];

    if (translation is Map<String, dynamic> &&
        translation.containsKey(langCode)) {
      return translation[langCode].toString();
    }

    if (translation is Map<String, dynamic> && translation.containsKey('en')) {
      return translation['en'].toString();
    }

    return key;
  }
}

class _MyLocalizationsDelegates
    extends LocalizationsDelegate<LocalizationService> {
  @override
  bool isSupported(Locale locale) {
    return ["en", "ar"].contains(locale.languageCode);
  }

  @override
  Future<LocalizationService> load(Locale locale) async {
    final LocalizationService myLocalizations = LocalizationService(
      locale: locale,
    );
    await myLocalizations.loadJsonFile();
    return myLocalizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<LocalizationService> old) {
    return false;
  }
}
