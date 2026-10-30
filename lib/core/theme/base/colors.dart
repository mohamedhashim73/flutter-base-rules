part of '../theme.dart';

/// Credixa palette derived from the logo's deep navy and royal blue tones.
///
/// The shared web language is built on cool neutral surfaces, a deep navy
/// sidebar, a royal-blue primary action colour, and semantic tinted surfaces.
/// Legacy token names are kept so existing screens can migrate incrementally.
class AppColors {
  // Brand
  static Color kPrimary = const Color(0xFF2F78D0);
  static Color kPrimaryLight = const Color(0xFF4A8FE0);
  static Color kAccent = const Color(0xFF163567);
  static Color kAccentLight = const Color(0xFF3D78C9);

  // Backgrounds
  static Color kBackground = const Color(0xFFF3F7FC);
  static Color kBackgroundDark = const Color(0xFF0B1220);
  static Color kSurface = const Color(0xFFFFFFFF);
  static Color kSurfaceDark = const Color(0xFF121C2D);
  static Color kCardBackground = const Color(0xFFFFFFFF);
  static Color kCardBackgroundDark = const Color(0xFF162238);
  static Color kSurfaceMuted = const Color(0xFFF7F9FD);
  static Color kSurfaceMutedDark = const Color(0xFF182337);

  // Text
  static Color kMainTxt = const Color(0xFF10213A);
  static Color kMainTxtDark = const Color(0xFFE8E8E8);
  static Color kBlack = const Color(0xFF000000);
  static Color kSecondary = const Color(0xFF64748B);
  static Color kSecondaryDark = const Color(0xFF9FB0C7);
  static Color kHint = const Color(0xFF718096);
  static Color kHintDark = const Color(0xFF718096);

  // Status & semantic
  static Color kError = const Color(0xFF9C1F17);
  static Color kErrorDark = const Color(0xFFEF4444);
  static Color kSuccess = const Color(0xFF16835D);
  static Color kWarning = const Color(0xFFA65A00);
  static Color kInfo = const Color(0xFF1D5A99);

  // Neutral UI
  static Color kWhite = const Color(0xFFFFFFFF);
  static Color kSoftWhite = const Color(0xFFF7F9FD);
  static Color kSoftGrey = const Color(0xFFD8D8D8);
  static Color kLightGrey = const Color(0xFFC0C0C0);
  static Color kWarmGrey = const Color(0xFF718096);
  static Color kDisabled = const Color(0xFFB9B9B9);
  static Color kRed = const Color(0xFF9C1F17);
  static Color kFront = const Color(0xFF10213A);
  static Color kShimmer = const Color(0xFFF1F5FB);
  static Color kShimmerBg = const Color(0xFFDCE6F3);
  static Color kBorder = const Color(0xFFDCE5F0);
  static Color kBorderDark = const Color(0xFF34445D);

  // Legacy compatibility
  static Color kMain = kPrimary;
  static Color kSec = const Color(0xFF163567);
  static Color kGolden = kAccent;
  static Color kFont3 = const Color(0xFFAAAAAA);
  static Color kFont2 = const Color(0xFF82817E);
  static Color kBrown = const Color(0xFF4A8FE0);
  static Color kOffWhite = const Color(0xFFFBF9F9);
  static Color kRaspberry = const Color(0xFFBA1F2B);
  static Color kSkyblue = const Color(0xFF78B2F0);
  static Color kLightblue = const Color(0xFFE8F1FC);
  static Color kGray = const Color(0xFF999999);
  static Color kDarkBlue = const Color(0xFF163567);
  static Color kMediumGray = const Color(0xFF7E7E7E);
  static Color kBlueTint = const Color(0xFFEAF2FC);
  static Color kSignInQuantityInactive = const Color(0xFF78B2F0);
  static Color kSignInSideEnabled = const Color(0xFFB9D5F5);
  static Color kSignInSideDisabled = const Color(0xFF78B2F0);

  // Landscape / desktop design tokens (shared with SJJL web)
  static Color kLandscapeBackground = const Color(0xFFF3F7FC);
  static Color kLandscapeHeadLine = const Color(0xFFEAF0F8);
  static Color kLandscapeInk = const Color(0xFF10213A);
  static Color kLandscapeMuted = const Color(0xFF64748B);
  static Color kLandscapeBorder = const Color(0xFFDCE5F0);
  static Color kLandscapeInputBorder = const Color(0xFFD7E1EE);
  static Color kLandscapeRowLine = const Color(0xFFEDF2F8);
  static Color kLandscapeNeutralPale = const Color(0xFFF3F7FC);

  static Color kLandscapePrimary = const Color(0xFF2F78D0);
  static Color kLandscapePrimaryText = const Color(0xFF1D5BA8);
  static Color kLandscapePrimaryPale = const Color(0xFFE6F0FC);
  static Color kLandscapePrimaryLine = const Color(0xFFC7DCF5);

  static Color kLandscapeSidebar = const Color(0xFF0B1F46);
  static Color kLandscapeSidebarText = const Color(0xFFC9D9F2);

  static Color kLandscapeWarning = const Color(0xFFA65A00);
  static Color kLandscapeWarningPale = const Color(0xFFFDEEDE);
  static Color kLandscapeWarningLine = const Color(0xFFF3D2AD);

  static Color kLandscapeDanger = const Color(0xFF9C1F17);
  static Color kLandscapeDangerPale = const Color(0xFFFBE4E1);
  static Color kLandscapeDangerLine = const Color(0xFFF1C2BD);

  static Color kLandscapeInfo = const Color(0xFF2867AE);
  static Color kLandscapeInfoPale = const Color(0xFFE8F1FC);
  static Color kLandscapeInfoLine = const Color(0xFFC5D9F1);

  // Kept as legacy token names for compatibility; values now follow the logo.
  static Color kLandscapeGold = const Color(0xFF3D68B2);
  static Color kLandscapeGoldPale = const Color(0xFFEAF1FC);
  static Color kLandscapeGoldLine = const Color(0xFFC9D9F1);
}
