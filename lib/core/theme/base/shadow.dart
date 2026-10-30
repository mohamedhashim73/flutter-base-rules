part of '../theme.dart';

/// Elevation tokens from the shared web design language.
///
/// Surfaces rely on hairline borders first and a very soft shadow second, so
/// cards never look heavy on top of the warm neutral background.
class AppShadow {
  static const Color _cardColor = Color(0x0F163567);
  static const Color _floatingColor = Color(0x1A163567);

  static List<BoxShadow> get card => const [
    BoxShadow(color: _cardColor, blurRadius: 18, offset: Offset(0, 6)),
  ];

  static List<BoxShadow> get soft => const [
    BoxShadow(color: _cardColor, blurRadius: 10, offset: Offset(0, 3)),
  ];

  static List<BoxShadow> get floating => const [
    BoxShadow(color: _floatingColor, blurRadius: 32, offset: Offset(0, 16)),
  ];

  static List<BoxShadow> get none => const [];
}
