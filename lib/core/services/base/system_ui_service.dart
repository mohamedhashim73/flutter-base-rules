import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class SystemUiService {
  const SystemUiService._();

  static Future<void> enableEdgeToEdge({
    Brightness navigationBarIconBrightness = Brightness.dark,
    Brightness statusBarIconBrightness = Brightness.dark,
  }) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: navigationBarIconBrightness,
        statusBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
        statusBarIconBrightness: statusBarIconBrightness,
        statusBarBrightness: statusBarIconBrightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }
}
