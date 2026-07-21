import 'package:base/core/constants/enums/notification_type_enum.dart';
import 'package:base/core/constants/extensions/int_extensions.dart';
import 'package:playx/playx.dart';

extension StringExtensions on String {
  String? validatorTxt({bool isNum = false, bool isOptional = true}) {
    try {
      final normalized = trim();
      if (normalized.isEmpty ||
          (isNum && double.tryParse(normalized) == null)) {
        return normalized.isEmpty && !isOptional
            ? 'برجاء إدخال القيمة'
            : normalized.isEmpty
            ? null
            : 'يرجى إدخال رقم صحيح';
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  NotifyType get toNotifyType {
    for (final type in NotifyType.values) {
      if (type.name == this) return type;
    }
    return NotifyType.unKnown;
  }

  String? get validEmail {
    if (trim().isEmpty) return 'البريد الإلكتروني مطلوب';
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(trim())) return 'البريد الإلكتروني غير صحيح';
    return null;
  }

  DateTime? get convertDMYToDate => DateFormat('dd-MM-yyyy').tryParse(this);
  DateTime? get convertApiDate =>
      DateFormat('yyyy-MM-dd HH:mm:ss').tryParse(this);

  /// Url
  bool get isLink {
    final linkRegex = RegExp(r'^(http|https)://[a-zA-Z0-9./?=_-]*$');
    return linkRegex.hasMatch(this);
  }

  T? toGetObject<T>(List<T> list, int Function(T item) idOf) {
    final id = int.tryParse(this);
    if (id == null) return null;
    return id.toGetObject(list, idOf);
  }
}
