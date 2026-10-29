part of '../theme.dart';

@immutable
class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  final Color background;
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color primaryPale;
  final Color surface;
  final Color surfaceMuted;
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
    required this.accent,
    required this.primaryPale,
    required this.surface,
    required this.surfaceMuted,
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
    accent: AppColors.kAccent,
    primaryPale: AppColors.kLandscapePrimaryPale,
    surface: AppColors.kSurface,
    surfaceMuted: AppColors.kSurfaceMuted,
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
    accent: AppColors.kAccentLight,
    primaryPale: const Color(0xFF173C30),
    surface: AppColors.kSurfaceDark,
    surfaceMuted: AppColors.kSurfaceMutedDark,
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
    Color? accent,
    Color? primaryPale,
    Color? surface,
    Color? surfaceMuted,
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
    accent: accent ?? this.accent,
    primaryPale: primaryPale ?? this.primaryPale,
    surface: surface ?? this.surface,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
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
      accent: Color.lerp(accent, other.accent, t)!,
      primaryPale: Color.lerp(primaryPale, other.primaryPale, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
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
    final isDark = isDarkModeOverride;
    final colors = isDark ? AppColorsTheme.dark() : AppColorsTheme.light();
    final textTheme = textThemeData(isDarkMode: isDark);
    final radius = BorderRadius.circular(AppDesignRadius.control);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primary,
      canvasColor: colors.background,
      dividerColor: colors.divider,
      cardColor: colors.card,
      fontFamily: AppFonts.main,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: Colors.white,
        primaryContainer: colors.primaryPale,
        onPrimaryContainer: colors.primary,
        secondary: colors.accent,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.kLandscapeGoldPale,
        onSecondaryContainer: AppColors.kLandscapeGold,
        error: colors.error,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.onSurface,
        surfaceContainerHighest: colors.surfaceMuted,
        onSurfaceVariant: colors.textSecondary,
        outline: colors.border,
        outlineVariant: colors.divider,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarThemeData(
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignRadius.card),
          side: BorderSide(color: colors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignRadius.dialog),
          side: BorderSide(color: colors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.kDisabled,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          backgroundColor: colors.surface,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: colors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.error, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryPale,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.textSecondary,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.kLandscapeInk,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignRadius.control),
        ),
      ),
      extensions: [colors],
    );
  }

  static ThemeData get light => themeData();
  static ThemeData get dark => themeData(isDarkModeOverride: true);

  static TextTheme textThemeData({required bool isDarkMode}) {
    final primary = isDarkMode ? AppColors.kMainTxtDark : AppColors.kMainTxt;
    final secondary = isDarkMode ? AppColors.kSecondaryDark : AppColors.kSecondary;
    TextStyle style(double size, FontWeight weight, [Color? color]) => TextStyle(
      color: color ?? primary,
      fontSize: size,
      fontWeight: weight,
      fontFamily: AppFonts.main,
      height: 1.45,
    );
    return TextTheme(
      displayLarge: style(34, FontWeight.w700),
      displayMedium: style(30, FontWeight.w700),
      displaySmall: style(26, FontWeight.w700),
      headlineLarge: style(24, FontWeight.w700),
      headlineMedium: style(22, FontWeight.w700),
      headlineSmall: style(20, FontWeight.w700),
      titleLarge: style(18, FontWeight.w700),
      titleMedium: style(16, FontWeight.w600),
      titleSmall: style(14, FontWeight.w600),
      bodyLarge: style(15, FontWeight.w400),
      bodyMedium: style(14, FontWeight.w400),
      bodySmall: style(12, FontWeight.w400, secondary),
      labelLarge: style(14, FontWeight.w600),
      labelMedium: style(12, FontWeight.w600, secondary),
      labelSmall: style(11, FontWeight.w500, secondary),
    );
  }

  static TextTheme textTheme({required bool isDarkMode}) =>
      textThemeData(isDarkMode: isDarkMode);

  /* Legacy theme kept through the themeData API above. */
  static ThemeData get legacyLight => ThemeData(
    useMaterial3: true,
    fontFamily: AppFonts.main,
    primaryColor: AppColors.kPrimary,
    scaffoldBackgroundColor: AppColors.kBackground,
    cardColor: AppColors.kCardBackground,
    appBarTheme: AppBarThemeData(
      foregroundColor: AppColors.kFront,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.kFront,
        fontFamily: AppFonts.main,
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

/// Shared radius tokens for the SJJL-derived design language.
class AppDesignRadius {
  static const double control = 10;
  static const double card = 16;
  static const double dialog = 20;
  static const double pill = 999;
}
