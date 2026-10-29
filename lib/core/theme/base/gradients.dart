part of '../theme.dart';

class AppGradients {
  /// Deep green shell used by the desktop navigation rail.
  static const LinearGradient sidebar = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [Color(0xFF14382F), Color(0xFF0C2A23)],
  );

  /// Emerald hero surface used for highlighted summaries.
  static const LinearGradient brand = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [Color(0xFF0F8A5F), Color(0xFF0A6B4A)],
  );

  static const LinearGradient gold = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [Color(0xFFD4A84B), Color(0xFFB8860B)],
  );

  static const LinearGradient page = LinearGradient(
    begin: AlignmentDirectional.topCenter,
    end: AlignmentDirectional.bottomCenter,
    colors: [Color(0xFFF6F8F7), Color(0xFFF0F3F2)],
  );
}
