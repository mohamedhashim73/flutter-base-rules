part of 'services.dart';

class LoggingService {
  static void showMsg(dynamic msg, {bool isOn = true}) {
    if (kDebugMode && isOn) {
      log("$msg");
    }
  }
}
