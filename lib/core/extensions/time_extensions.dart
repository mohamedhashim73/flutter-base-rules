part of 'extensions.dart';
extension DateFormatting on DateTime {
  String get toDayMonthYear {
    return DateFormat('dd-MM-yyyy').format(this);
  }

  /// e.g. 17/2/2025 09:40:00
  String get toDisplayDateTime {
    return DateFormat('d/M/yyyy HH:mm:ss').format(this);
  }

  /// e.g. 17 أبريل 2025
  String get toDayMonthYearArabic {
    return DateFormat('d MMMM yyyy', 'ar').format(this);
  }

  /// e.g. أبريل 2025
  String get toMonthYearArabic {
    return DateFormat('MMMM yyyy', 'ar').format(this);
  }

  /// e.g. 2025
  String get toYearArabic {
    return DateFormat('yyyy', 'ar').format(this);
  }

  /// e.g. 2026-05-25 08:00:00 (for delivery time API)
  String get toDeliveryDateTime {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(this);
  }

  /// e.g. 15 يناير 2026 (localized date in Arabic)
  String get toLocalizedDate {
    return DateFormat('d MMMM yyyy', 'ar').format(this);
  }

  /// e.g. 07:00 ص (localized time in Arabic with AM/PM)
  String get toLocalizedTime {
    return DateFormat('hh:mm a', 'ar').format(this);
  }

  /// e.g. اليوم الثلاثاء ، 12 مارس (Today + day name + date in Arabic)
  String get toConfirmDate {
    final dayName = DateFormat('EEEE', 'ar').format(this);
    final date = DateFormat('d MMMM', 'ar').format(this);
    return 'اليوم $dayName ، $date';
  }

  /// e.g. من 10:00 ص إلى 12:00 م (from start time to end time +2 hours)
  String get toConfirmTimeRange {
    final startTime = toLocalizedTime;
    final endTime = add(const Duration(hours: 2)).toLocalizedTime;
    return 'من $startTime إلى $endTime';
  }

  /// e.g. 29 أكتوبر 2025 • 04:07م (date with time in Arabic format)
  String get toOrderHistoryDateTime {
    final date = DateFormat('d MMMM yyyy', 'ar').format(this);
    final time =
        DateFormat('hh:mm', 'ar').format(this) + (hour >= 12 ? 'م' : 'ص');
    return '$date • $time';
  }

  /// e.g. يناير 13 - الساعة 04:12
  String get toTimelineLogDate {
    final month = DateFormat('MMMM', 'ar').format(this);
    final day = DateFormat('d', 'en').format(this);
    final time = DateFormat('HH:mm', 'en').format(this);
    return '$month $day - الساعة $time';
  }

  String get toArabicRelativeTime {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} ${diff.inDays == 1 ? 'يوم' : 'أيام'}';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ${diff.inHours == 1 ? 'ساعة' : 'ساعات'}';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} ${diff.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    return 'الآن';
  }

  String get toArabicRemainingTime {
    final now = DateTime.now();
    if (isBefore(now)) return 'انتهت صلاحيتة';
    final remaining = difference(now);
    if (remaining.inDays >= 1) {
      return 'صالح لمدة ${remaining.inDays} ${remaining.inDays == 1 ? 'يوم' : 'أيام'}';
    }
    if (remaining.inHours >= 1) {
      return 'صالح لمدة ${remaining.inHours} ${remaining.inHours == 1 ? 'ساعة' : 'ساعات'}';
    }
    if (remaining.inMinutes >= 1) {
      return 'صالح لمدة ${remaining.inMinutes} ${remaining.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    }
    return 'صالح لمدة أقل من دقيقة';
  }
}
