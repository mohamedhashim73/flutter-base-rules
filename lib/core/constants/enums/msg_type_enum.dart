import 'dart:ui';

enum MsgType {
  info,
  error,
  success,
  canceled,
  insufficientBalance,
  outsideWorkingHours;

  String get emoji {
    switch (this) {
      case info:
        return '😔';
      case error || canceled:
        return '❌';
      case success:
        return '👌';
      case insufficientBalance:
        return '🤔';
      case outsideWorkingHours:
        return '🥺';
    }
  }

  String get title {
    switch (this) {
      case success:
        return 'تم بنجاح';
      case error:
        return 'حدث خطأ';
      case canceled:
        return 'تم الإلغاء';
      case info:
        return 'تنبيه';
      case insufficientBalance:
        return 'رصيد نقاطك غير كافي!';
      case outsideWorkingHours:
        return 'التطبيق خارج مواعيد العمل حالياً';
    }
  }

  String get btnLabel {
    switch (this) {
      case success:
        return 'متابعة';
      case error:
        return 'حسنًا';
      case canceled:
        return 'تواصلي مع الدعم يساعدك';
      case info:
        return 'حسنًا';
      case insufficientBalance:
        return 'موافقه';
      case outsideWorkingHours:
        return 'عرض الـمواعيد الـمتاحة';
    }
  }

  Color get sheetBgColor {
    switch (this) {
      case success:
        return const Color(0xFFEDFFF2);
      case error || canceled:
        return const Color(0xFFFFEDED);
      case insufficientBalance || info:
        return const Color(0xFFFFFDED);
      case outsideWorkingHours:
        return const Color(0xFFFBEDFF);
    }
  }

  Color get topShadowColor {
    switch (this) {
      case success:
        return const Color(0xFFA6E8B7);
      case error || canceled:
        return const Color(0xFFF5C3C3);
      case insufficientBalance || info:
        return const Color(0xFFFFF9CC);
      case outsideWorkingHours:
        return const Color(0xFFF1C2FF);
    }
  }

  Color get btnColor {
    switch (this) {
      case success:
        return const Color(0xFF34C759);
      case error || canceled:
        return const Color(0xFFE04A4A);
      case insufficientBalance || info:
        return const Color(0xFFFFA658);
      case outsideWorkingHours:
        return const Color(0xFFDB5EFF);
    }
  }
}
