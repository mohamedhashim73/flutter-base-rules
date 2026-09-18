part of 'extensions.dart';
extension DoubleExtensions on double {
  String get percentageTxt => this == 100 ? "مكتمل" : "قيد التقدم";
  String currency({bool isSuffix = true}) {
    String result = formatted;
    if (isSuffix) {
      return "$result ج";
    }
    return "ج $result";
  }
  String get withMinutes =>
      this == 1 || this > 10 ? "$toInt دقيقة" : "$toInt دقائق";

  String get formatted => toLocalizedEnglishNumber;
}
