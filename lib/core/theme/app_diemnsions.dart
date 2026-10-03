part of 'theme.dart';

/// Reusable layout tokens. Keep feature-specific measurements out of this file.
class AppDimensions {
  static double get s1 => 1.r;
  static double get s2 => 2.r;
  static double get s3 => 3.r;
  static double get s4 => 4.r;
  static double get s5 => 5.r;
  static double get s6 => 6.r;
  static double get s7 => 7.r;
  static double get s8 => 8.r;
  static double get s9 => 9.r;
  static double get s10 => 10.r;
  static double get s11 => 11.r;
  static double get s12 => 12.r;
  static double get s13 => 13.r;
  static double get s14 => 14.r;
  static double get s15 => 15.r;
  static double get s16 => 16.r;
  static double get s17 => 17.r;
  static double get s18 => 18.r;
  static double get s19 => 19.r;
  static double get s20 => 20.r;
  static double get s21 => 21.r;
  static double get s22 => 22.r;
  static double get s23 => 23.r;
  static double get s24 => 24.r;
  static double get s25 => 25.r;
  static double get s26 => 26.r;
  static double get s27 => 27.r;
  static double get s28 => 28.r;
  static double get s29 => 29.r;
  static double get s30 => 30.r;
  static double get s31 => 31.r;
  static double get s32 => 32.r;
  static double get s33 => 33.r;
  static double get s34 => 34.r;
  static double get s35 => 35.r;
  static double get s36 => 36.r;
  static double get s37 => 37.r;
  static double get s38 => 38.r;
  static double get s39 => 39.r;
  static double get s40 => 40.r;
  static double get s41 => 41.r;
  static double get s42 => 42.r;
  static double get s43 => 43.r;
  static double get s44 => 44.r;
  static double get s45 => 45.r;
  static double get s46 => 46.r;
  static double get s47 => 47.r;
  static double get s48 => 48.r;
  static double get s49 => 49.r;
  static double get s50 => 50.r;
  static double get s51 => 51.r;
  static double get s52 => 52.r;
  static double get s53 => 53.r;
  static double get s54 => 54.r;
  static double get s55 => 55.r;
  static double get s56 => 56.r;
  static double get s57 => 57.r;
  static double get s58 => 58.r;
  static double get s59 => 59.r;
  static double get s60 => 60.r;
  static double get s61 => 61.r;
  static double get s62 => 62.r;
  static double get s63 => 63.r;
  static double get s64 => 64.r;
  static double get s65 => 65.r;
  static double get s66 => 66.r;
  static double get s67 => 67.r;
  static double get s68 => 68.r;
  static double get s69 => 69.r;
  static double get s70 => 70.r;
  static double get s71 => 71.r;
  static double get s72 => 72.r;
  static double get s73 => 73.r;
  static double get s74 => 74.r;
  static double get s75 => 75.r;
  static double get s76 => 76.r;
  static double get s77 => 77.r;
  static double get s78 => 78.r;
  static double get s79 => 79.r;
  static double get s80 => 80.r;
  static double get s81 => 81.r;
  static double get s82 => 82.r;
  static double get s83 => 83.r;
  static double get s84 => 84.r;
  static double get s85 => 85.r;
  static double get s86 => 86.r;
  static double get s87 => 87.r;
  static double get s88 => 88.r;
  static double get s89 => 89.r;
  static double get s90 => 90.r;
  static double get s91 => 91.r;
  static double get s92 => 92.r;
  static double get s93 => 93.r;
  static double get s94 => 94.r;
  static double get s95 => 95.r;
  static double get s96 => 96.r;
  static double get s97 => 97.r;
  static double get s98 => 98.r;
  static double get s99 => 99.r;
  static double get s100 => 100.r;

  static double get zero => 0.r;
  static double get xxs => 4.r;
  static double get xs => 8.r;
  static double get sm => 12.r;
  static double get md => 16.r;
  static double get lg => 24.r;
  static double get xl => 32.r;
  static double get xxl => 48.r;

  static double get iconSm => 16.r;
  static double get iconMd => 24.r;
  static double get iconLg => 32.r;
  static double get controlHeight => 48.r;
  static double get controlHeightLarge => 56.r;
  static double get bottomBarHeight => 70.r;
  static double get screenWidth =>
      MediaQuery.of(AppRoutes.currentContext).size.width;
  static double get dialogWidth => AppRoutes.currentContext.isLandscape
      ? screenWidth * .3
      : screenWidth * .85;

  static BorderRadius get radiusSm => BorderRadius.circular(sm);
  static BorderRadius get radiusMd => BorderRadius.circular(md);
  static BorderRadius get radiusLg => BorderRadius.circular(lg);
  static BorderRadius get radiusXl => BorderRadius.circular(xl);

  static EdgeInsets get insetXxs => EdgeInsets.all(xxs);
  static EdgeInsets get insetXs => EdgeInsets.all(xs);
  static EdgeInsets get insetSm => EdgeInsets.all(sm);
  static EdgeInsets get insetMd => EdgeInsets.all(md);
  static EdgeInsets get insetLg => EdgeInsets.all(lg);
  static EdgeInsets get horizontalSm => EdgeInsets.symmetric(horizontal: sm);
  static EdgeInsets get horizontalMd => EdgeInsets.symmetric(horizontal: md);
  static EdgeInsets get horizontalLg => EdgeInsets.symmetric(horizontal: lg);
  static EdgeInsets get verticalSm => EdgeInsets.symmetric(vertical: sm);
  static EdgeInsets get verticalMd => EdgeInsets.symmetric(vertical: md);
  static EdgeInsets get verticalLg => EdgeInsets.symmetric(vertical: lg);
  static EdgeInsets get screenPadding => horizontalLg;
  static EdgeInsets get listPadding => EdgeInsets.only(bottom: xl);

  static EdgeInsets contentPadding({double? top}) =>
      EdgeInsets.fromLTRB(lg, top ?? md, lg, 0);

  static BoxBorder get border =>
      Border.all(color: const Color(0xffE5E5E5), width: 1.r);

  static BoxBorder get skeletonBorder => Border.all(
    color: const Color(0xff2684FF).withValues(alpha: 0.04),
    width: 1,
  );
}
