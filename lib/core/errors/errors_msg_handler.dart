import 'package:base/core/constants/strings.dart';
import 'package:base/core/services/logging_service.dart';

class ErrorHandler {
  static String error(dynamic msg) {
    LoggingService.showMsg("ErrorHandler.Msg $msg");
    try {
      return msg is Map
          ? msg['message']
          : msg is String && msg.isNotEmpty
          ? msg
          : AppStrings.kSomethingWentWrong;
    } catch (e) {
      return AppStrings.kSomethingWentWrong;
    }
  }
}
