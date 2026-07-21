import 'package:flutter/widgets.dart';
import 'package:playx/playx.dart';
import 'package:base/core/constants/routes.dart';

class Dim {
  static double btnLTxtSize = 20.sp;
  static double bottomNavigationheight = 174.r;
  static EdgeInsets gradientPageBtn = EdgeInsets.only(
    left: Dim.bodyHSpace,
    right: Dim.bodyHSpace,
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
      ? AppRoutes.currentContext.width * .3
      : AppRoutes.currentContext.width * .85;
  static double bPageSpace =
      (AppRoutes.currentContext.isLandscape == true ? 16 : 24).r;
  static BorderRadius get max => BorderRadius.circular(24.r);
  static BorderRadius get main => BorderRadius.circular(16.r);
  static BorderRadius get min => BorderRadius.circular(12.r);
  static EdgeInsets get zeroInsets => EdgeInsets.zero;
  static EdgeInsets get listViewPadding =>
      EdgeInsets.only(bottom: bSpaceIncaseFloatingBtn);
  static EdgeInsets bodyPadding({double? tSpace}) =>
      EdgeInsets.fromLTRB(bodyHSpace, tSpace ?? vSpace, bodyHSpace, 0);
}
