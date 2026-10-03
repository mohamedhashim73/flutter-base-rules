part of 'theme.dart';

@immutable
class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  final Color background;
  final Color primary;
  final Color primaryLight;
  final Color surface;
  final Color card;
  final Color onSurface;
  final Color textSecondary;
  final Color divider;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;

  const AppColorsTheme({
    required this.background,
    required this.primary,
    required this.primaryLight,
    required this.surface,
    required this.card,
    required this.onSurface,
    required this.textSecondary,
    required this.divider,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
  });

  factory AppColorsTheme.light() => AppColorsTheme(
    background: AppColors.kBackground,
    primary: AppColors.kPrimary,
    primaryLight: AppColors.kPrimaryLight,
    surface: AppColors.kSurface,
    card: AppColors.kCardBackground,
    onSurface: AppColors.kMainTxt,
    textSecondary: AppColors.kSecondary,
    divider: AppColors.kBorder,
    border: AppColors.kBorder,
    success: AppColors.kSuccess,
    warning: AppColors.kWarning,
    error: AppColors.kError,
  );

  factory AppColorsTheme.dark() => AppColorsTheme(
    background: AppColors.kBackgroundDark,
    primary: AppColors.kPrimary,
    primaryLight: AppColors.kPrimaryLight,
    surface: AppColors.kSurfaceDark,
    card: AppColors.kCardBackgroundDark,
    onSurface: AppColors.kMainTxtDark,
    textSecondary: AppColors.kSecondaryDark,
    divider: AppColors.kBorderDark,
    border: AppColors.kBorderDark,
    success: AppColors.kSuccess,
    warning: AppColors.kWarning,
    error: AppColors.kErrorDark,
  );

  @override
  AppColorsTheme copyWith({
    Color? background,
    Color? primary,
    Color? primaryLight,
    Color? surface,
    Color? card,
    Color? onSurface,
    Color? textSecondary,
    Color? divider,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
  }) => AppColorsTheme(
    background: background ?? this.background,
    primary: primary ?? this.primary,
    primaryLight: primaryLight ?? this.primaryLight,
    surface: surface ?? this.surface,
    card: card ?? this.card,
    onSurface: onSurface ?? this.onSurface,
    textSecondary: textSecondary ?? this.textSecondary,
    divider: divider ?? this.divider,
    border: border ?? this.border,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
  );

  @override
  AppColorsTheme lerp(ThemeExtension<AppColorsTheme>? other, double t) {
    if (other is! AppColorsTheme) return this;
    return AppColorsTheme(
      background: Color.lerp(background, other.background, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

class AppTheme {
  static ThemeData themeData({bool isDarkModeOverride = false}) {
    final colors = isDarkModeOverride
        ? AppColorsTheme.dark()
        : AppColorsTheme.light();
    return ThemeData(
      useMaterial3: true,
      brightness: isDarkModeOverride ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primary,
      colorScheme: ColorScheme(
        brightness: isDarkModeOverride ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: AppColors.kWhite,
        secondary: colors.primaryLight,
        onSecondary: AppColors.kWhite,
        error: colors.error,
        onError: AppColors.kWhite,
        surface: colors.surface,
        onSurface: colors.onSurface,
      ),
      cardColor: colors.card,
      dividerColor: colors.divider,
      fontFamily: AppFonts.main,
      textTheme: textTheme(isDarkMode: isDarkModeOverride),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDarkModeOverride
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      extensions: [colors],
    );
  }

  static ThemeData get light => themeData();
  static ThemeData get dark => themeData(isDarkModeOverride: true);

  static TextTheme textTheme({required bool isDarkMode}) => TextTheme(
    bodyLarge: TextStyle(
      color: isDarkMode ? AppColors.kMainTxtDark : AppColors.kMainTxt,
      fontSize: AppFontSize.bodyLarge,
      fontFamily: AppFonts.main,
    ),
    bodyMedium: TextStyle(
      color: isDarkMode ? AppColors.kSecondaryDark : AppColors.kSecondary,
      fontSize: AppFontSize.bodyMedium,
      fontFamily: AppFonts.main,
    ),
    titleLarge: TextStyle(
      color: isDarkMode ? AppColors.kMainTxtDark : AppColors.kMainTxt,
      fontSize: AppFontSize.titleLarge,
      fontFamily: AppFonts.main,
      fontWeight: FontWeight.w600,
    ),
  );

  /* Legacy theme kept through the themeData API above. */
  static ThemeData get legacyLight => ThemeData(
    useMaterial3: true,
    fontFamily: AppConstants.kMainFont,
    primaryColor: AppColors.kPrimary,
    scaffoldBackgroundColor: AppColors.kBackground,
    cardColor: AppColors.kCardBackground,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.kSurface,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.kPrimary,
      unselectedItemColor: AppColors.kSecondary,
      elevation: 0,
    ),
    appBarTheme: AppBarTheme(
      foregroundColor: AppColors.kFront,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      // Configures the system UI overlays (Status bar at the top and Navigation bar at the bottom)
      // to achieve a true edge-to-edge immersive layout, overriding default OS colors.
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.kFront,
        fontFamily: AppConstants.kMainFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.kPrimary,
      foregroundColor: AppColors.kWhite,
      elevation: 0,
    ),
  );
}
