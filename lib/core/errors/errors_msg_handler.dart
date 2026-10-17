part of 'errors.dart';

class ErrorHandler {
  static String error(dynamic msg) {
    LoggingService.showMsg("ErrorHandler.Msg $msg");
    try {
      if (msg is BackendFailure) return msg.safeMessage;
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
