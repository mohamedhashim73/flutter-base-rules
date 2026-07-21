import 'dart:developer';
import 'package:flutter/foundation.dart';

class LoggingService {
  static void showMsg(dynamic msg, {bool isOn = true}) {
    if (kDebugMode && isOn) {
      log("$msg");
    }
  }
}
