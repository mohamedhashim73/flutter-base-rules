part of 'theme.dart';

class AppColors {
  // Primary & Accent
  static Color kPrimary = const Color(0xFF07B7FA);
  static Color kPrimaryLight = const Color(0xFF2E7D65);
  static Color kAccent = const Color(0xFFB8860B);
  static Color kAccentLight = const Color(0xFFD4A84B);

  // Backgrounds
  static Color kBackground = const Color(0xFFF5F5F0);
  static Color kBackgroundDark = const Color(0xFF121212);
  static Color kSurface = const Color(0xFFFFFFFF);
  static Color kSurfaceDark = const Color(0xFF1E1E1E);
  static Color kCardBackground = const Color(0xFFFFFFFF);
  static Color kCardBackgroundDark = const Color(0xFF2C2C2C);

  // Text
  static Color kMainTxt = const Color(0xFF1B1620);
  static Color kMainTxtDark = const Color(0xFFE8E8E8);
  static Color kBlack = const Color(0xFF000000);
  static Color kSecondary = const Color(0xFF6B7280);
  static Color kSecondaryDark = const Color(0xFF9CA3AF);
  static Color kHint = const Color(0xFF82817E);
  static Color kHintDark = const Color(0xFF6B7280);

  // Status & Semantic
  static Color kError = const Color(0xFFC10007);
  static Color kErrorDark = const Color(0xFFEF4444);
  static Color kSuccess = const Color(0xFF22C55E);
  static Color kWarning = const Color(0xFFE17100);
  static Color kInfo = const Color(0xFF155DFC);

  // UI
  static Color kSoftWhite = const Color(0xFFFAFAFA);
  static Color kSoftGrey = const Color(0xFFD8D8D8);
  static Color kLightGrey = const Color(0xFFC0C0C0);
  static Color kWarmGrey = const Color(0xFF82817E);
  static Color kDisabled = const Color(0xFFD6D6D6);
  static Color kRed = const Color(0xFFC10007);
  static Color kFront = const Color(0xFF1A1A1A);
  static Color kShimmer = Colors.black.withOpacity(0.04);
  static Color kBorder = const Color(0xFFE5E7EB);
  static Color kBorderDark = const Color(0xFF374151);

  // Legacy compatibility
  static Color kMain = kPrimary;
  static Color kSec = const Color(0xFF030332);
  static Color kGolden = kAccent;
  static Color kFont3 = const Color(0xFFAAAAAA);
  static Color kFont2 = const Color(0xFF82817E);
  static Color kBrown = const Color(0xFFF4D245);
  static Color kOffWhite = const Color(0xFFFBF9F9);
  static Color kRaspberry = const Color(0xFFBA1F2B);

  // Decoration
  static BoxDecoration kCardDecoration = BoxDecoration(
    color: Theme.of(AppRoutes.currentContext).cardColor,
    borderRadius: AppRoutes.currentContext.main,
    border: AppDimensions.kMainBorder,
    boxShadow: [
      BoxShadow(
        color: AppColors.kPrimary.withOpacity(0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Updated
  static Color kSkyblue = const Color(0xFF8EE2FF);
  static Color kLightblue = const Color(0xFFE0F2F9);
  static Color kWhite = const Color(0xFFFFFFFF);
  static Color kGray = const Color(0xFF999999);
  static Color kDarkBlue = const Color(0xFF353A62);
  static Color kMediumGray = const Color(0xFF7E7E7E);
  static Color kBlueTint = const Color(0xFFEEF5FF);
  static Color kSignInQuantityInactive = const Color(0xFF69BADF);
  static Color kSignInSideEnabled = const Color(0xFF9BCEE5);
  static Color kSignInSideDisabled = const Color(0xFF69BADF);
}
