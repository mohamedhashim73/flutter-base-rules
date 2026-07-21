import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/constants.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
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
