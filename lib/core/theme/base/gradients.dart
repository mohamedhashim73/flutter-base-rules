part of '../theme.dart';

class AppGradients {
  /// Deep navy shell used by the desktop navigation rail.
  static const LinearGradient sidebar = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [Color(0xFF173A78), Color(0xFF0A1D43)],
  );

  /// Royal-blue hero surface used for highlighted summaries.
  static const LinearGradient brand = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [Color(0xFF3B82D0), Color(0xFF1C4F9A)],
  );

  static const LinearGradient gold = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [Color(0xFF78A7E0), Color(0xFF3D68B2)],
  );

  static const LinearGradient page = LinearGradient(
    begin: AlignmentDirectional.topCenter,
    end: AlignmentDirectional.bottomCenter,
    colors: [Color(0xFFF8FAFD), Color(0xFFF1F5FB)],
  );
}
