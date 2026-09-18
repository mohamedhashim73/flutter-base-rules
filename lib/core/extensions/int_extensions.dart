part of 'extensions.dart';
extension IntExtensions on int {
  Widget get vrSpace => SizedBox(height: toDouble());
  Widget get hrSpace => SizedBox(width: toDouble());
  T? toGetObject<T>(List<T> list, int Function(T item) idOf) {
    for (final item in list) {
      if (idOf(item) == this) return item;
    }
    return null;
  }
}
