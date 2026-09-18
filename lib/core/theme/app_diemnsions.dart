part of 'theme.dart';

class AppDimensions {
  static double btnLTxtSize = 20.sp;
  static double bottomNavigationheight = 174.r;
  static EdgeInsets gradientPageBtn = EdgeInsets.only(
    left: AppDimensions.bodyHSpace,
    right: AppDimensions.bodyHSpace,
    top: 18.r,
    bottom: 41.r,
  );
  static EdgeInsets btnLPadding = EdgeInsets.all(18.r);
  static EdgeInsets btnSPadding = EdgeInsets.symmetric(
    horizontal: 18.r,
    vertical: 14.r,
  );
  static double badgeVSpace = 22.r;
  static double badgeLHSpace = 44.r;
  static double btnCornerLSpace = 10.r;
  static double btnCornerSSpace = 6.r;
  static double badgeSHSpace = 30.r;
  static double hSpace = 16.r;
  static double btnHeight = 70.r;
  static double vSpace = 16.r;
  static double bSpaceIncaseFloatingBtn = 74.r;
  static double bSpaceList = 24.r;
  static double pairHSpace = (AppRoutes.currentContext.isLandscape ? 24 : 12).r;
  static double bodyHSpace = 24.r;
  static double bodyHMinSpace = 12.r;
  static double dialogWidth = AppRoutes.currentContext.isLandscape
      ? width * .3
      : width * .85;
  static double bPageSpace =
      (AppRoutes.currentContext.isLandscape == true ? 16 : 24).r;
  static BorderRadius get max => BorderRadius.circular(24.r);
  static BorderRadius get main => BorderRadius.circular(16.r);
  static BorderRadius get min => BorderRadius.circular(12.r);
  static double get width => MediaQuery.of(AppRoutes.currentContext).size.width;
  static EdgeInsets get zeroInsets => EdgeInsets.zero;
  static EdgeInsets get listViewPadding =>
      EdgeInsets.only(bottom: bSpaceIncaseFloatingBtn);
  static EdgeInsets bodyPadding({double? tSpace}) =>
      EdgeInsets.fromLTRB(bodyHSpace, tSpace ?? vSpace, bodyHSpace, 0);
  static BorderRadius get kMainRadius => BorderRadius.circular(10.r);
  static BorderRadius get kMaxRadius => BorderRadius.circular(22.r);
  static BoxBorder get kMainBorder =>
      Border.all(color: const Color(0xffE5E5E5), width: 1.r);
      static BoxBorder kSkeletonLoadingBorder = Border.all(
    color: const Color(0xff2684FF).withValues(alpha: 0.04),
    width: 1,
  );
}
