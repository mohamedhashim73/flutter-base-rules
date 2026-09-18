part of 'theme.dart';

class AppGradients {
  static final Gradient basic = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: const [Color(0x00389ECC), Color(0xFFE7E7E7)],
  );
  static final Gradient secondary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.kSkyblue, AppColors.kWhite, AppColors.kWhite],
  );
  static Gradient page({Color? color}) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0, 0.75, 1.0],
    colors: [color ?? AppColors.kSkyblue, AppColors.kWhite, AppColors.kWhite],
  );
  static final Gradient bottomNavigationSecondary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.kWhite,
      AppColors.kWhite.withOpacity(0.7),
      AppColors.kWhite,
      AppColors.kWhite,
    ],
  );
}
