part of '../theme.dart';

/// Credixa palette derived from the SJJL web design system.
///
/// The shared web language is built on warm neutral surfaces, a deep green
/// sidebar, an emerald primary action colour, and semantic tinted surfaces.
/// Legacy token names are kept so existing screens can migrate incrementally.
class AppColors {
  // Brand
  static Color kPrimary = const Color(0xFF0F8A5F);
  static Color kPrimaryLight = const Color(0xFF2E7D65);
  static Color kAccent = const Color(0xFFB8860B);
  static Color kAccentLight = const Color(0xFFD4A84B);

  // Backgrounds
  static Color kBackground = const Color(0xFFF0F3F2);
  static Color kBackgroundDark = const Color(0xFF121212);
  static Color kSurface = const Color(0xFFFFFFFF);
  static Color kSurfaceDark = const Color(0xFF1E1E1E);
  static Color kCardBackground = const Color(0xFFFFFFFF);
  static Color kCardBackgroundDark = const Color(0xFF2C2C2C);
  static Color kSurfaceMuted = const Color(0xFFF6F8F7);
  static Color kSurfaceMutedDark = const Color(0xFF252A28);

  // Text
  static Color kMainTxt = const Color(0xFF10213A);
  static Color kMainTxtDark = const Color(0xFFE8E8E8);
  static Color kBlack = const Color(0xFF000000);
  static Color kSecondary = const Color(0xFF6A778A);
  static Color kSecondaryDark = const Color(0xFF9CA3AF);
  static Color kHint = const Color(0xFF82817E);
  static Color kHintDark = const Color(0xFF6B7280);

  // Status & semantic
  static Color kError = const Color(0xFF9C1F17);
  static Color kErrorDark = const Color(0xFFEF4444);
  static Color kSuccess = const Color(0xFF0F8A5F);
  static Color kWarning = const Color(0xFFA65A00);
  static Color kInfo = const Color(0xFF1D5A99);

  // Neutral UI
  static Color kWhite = const Color(0xFFFFFFFF);
  static Color kSoftWhite = const Color(0xFFF6F8F7);
  static Color kSoftGrey = const Color(0xFFD8D8D8);
  static Color kLightGrey = const Color(0xFFC0C0C0);
  static Color kWarmGrey = const Color(0xFF82817E);
  static Color kDisabled = const Color(0xFFB9B9B9);
  static Color kRed = const Color(0xFF9C1F17);
  static Color kFront = const Color(0xFF10213A);
  static Color kShimmer = const Color(0xFFF6F7F9);
  static Color kShimmerBg = const Color(0xFFE3E5E8);
  static Color kBorder = const Color(0xFFE3E8E5);
  static Color kBorderDark = const Color(0xFF374151);

  // Legacy compatibility
  static Color kMain = kPrimary;
  static Color kSec = const Color(0xFF103A31);
  static Color kGolden = kAccent;
  static Color kFont3 = const Color(0xFFAAAAAA);
  static Color kFont2 = const Color(0xFF82817E);
  static Color kBrown = const Color(0xFFF4D245);
  static Color kOffWhite = const Color(0xFFFBF9F9);
  static Color kRaspberry = const Color(0xFFBA1F2B);
  static Color kSkyblue = const Color(0xFF8EE2FF);
  static Color kLightblue = const Color(0xFFE0F2F9);
  static Color kGray = const Color(0xFF999999);
  static Color kDarkBlue = const Color(0xFF353A62);
  static Color kMediumGray = const Color(0xFF7E7E7E);
  static Color kBlueTint = const Color(0xFFEEF5FF);
  static Color kSignInQuantityInactive = const Color(0xFF69BADF);
  static Color kSignInSideEnabled = const Color(0xFF9BCEE5);
  static Color kSignInSideDisabled = const Color(0xFF69BADF);

  // Landscape / desktop design tokens (shared with SJJL web)
  static Color kLandscapeBackground = const Color(0xFFF0F3F2);
  static Color kLandscapeHeadLine = const Color(0xFFE9EEEB);
  static Color kLandscapeInk = const Color(0xFF10213A);
  static Color kLandscapeMuted = const Color(0xFF6A778A);
  static Color kLandscapeBorder = const Color(0xFFE3E8E5);
  static Color kLandscapeInputBorder = const Color(0xFFDFE5E2);
  static Color kLandscapeRowLine = const Color(0xFFEEF2F0);
  static Color kLandscapeNeutralPale = const Color(0xFFF0F3F2);

  static Color kLandscapePrimary = const Color(0xFF0F8A5F);
  static Color kLandscapePrimaryText = const Color(0xFF0A6B4A);
  static Color kLandscapePrimaryPale = const Color(0xFFE4F4EC);
  static Color kLandscapePrimaryLine = const Color(0xFFCFE3DA);

  static Color kLandscapeSidebar = const Color(0xFF14382F);
  static Color kLandscapeSidebarText = const Color(0xFFBCD6CB);

  static Color kLandscapeWarning = const Color(0xFFA65A00);
  static Color kLandscapeWarningPale = const Color(0xFFFDEEDE);
  static Color kLandscapeWarningLine = const Color(0xFFF3D2AD);

  static Color kLandscapeDanger = const Color(0xFF9C1F17);
  static Color kLandscapeDangerPale = const Color(0xFFFBE4E1);
  static Color kLandscapeDangerLine = const Color(0xFFF1C2BD);

  static Color kLandscapeInfo = const Color(0xFF1D5A99);
  static Color kLandscapeInfoPale = const Color(0xFFE2EEFA);
  static Color kLandscapeInfoLine = const Color(0xFFBCD6EF);

  static Color kLandscapeGold = const Color(0xFFB8860B);
  static Color kLandscapeGoldPale = const Color(0xFFF8F1DF);
  static Color kLandscapeGoldLine = const Color(0xFFEAD9AC);
}
