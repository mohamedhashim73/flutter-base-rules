// ignore: file_names
import 'package:flutter/material.dart';
import 'package:playx/playx.dart';
import '../../theme/app_colors.dart';

extension BuildContextExtensions on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  TextTheme get txtTheme => Theme.of(this).textTheme;
  BorderRadius get max => BorderRadius.circular(22);
  BorderRadius get main => BorderRadius.circular(14);
  BorderRadius get min => BorderRadius.circular(10);
  EdgeInsets get listViewPadding => const EdgeInsets.only(bottom: 24);
  EdgeInsets get paddingZero => EdgeInsets.zero;
  EdgeInsets get scaffoldPadding => EdgeInsets.symmetric(horizontal: 24);
  BoxBorder get mainBorder => Border.all(color: AppColors.kSoftGrey, width: 1);
  InputBorder get enabledInputBorder => OutlineInputBorder(
    borderRadius: main,
    borderSide: BorderSide(color: AppColors.kLightGrey, width: 1),
  );
  InputBorder get errorInputBorder => OutlineInputBorder(
    borderRadius: main,
    borderSide: BorderSide(color: AppColors.kRed, width: 1),
  );
  InputBorder get focusedInputBorder => OutlineInputBorder(
    borderRadius: main,
    borderSide: BorderSide(color: AppColors.kMain, width: 1),
  );
  BoxBorder get skeletonLoadingBorder =>
      Border.all(color: const Color(0xff2684FF).withOpacity(0.04), width: 1);
  EdgeInsets get cardPadding => EdgeInsets.all(14);
  BoxBorder get basic =>
      BoxBorder.all(color: AppColors.kSecondary.withOpacity(0.12), width: 1);
  double concatenatePaddingOnBottom(double val) => val + bottomPadding;
  double concatenatePaddingOnTop(double val) => val + topPadding;
  double get topPadding => MediaQuery.of(this).padding.top;
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
  double get bottomInsets => MediaQuery.of(this).viewInsets.bottom;
  double get screenHeight => MediaQuery.of(this).size.height;
  Orientation get orientation => MediaQuery.of(this).orientation;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => !isLandscape;
  bool get isTablet => MediaQuery.of(this).size.width >= 600;
  double get screenWidth => MediaQuery.of(this).size.width;
  int get crossAxisCount {
    if (screenWidth > 900) {
      return 5;
    } else if (screenWidth > 600) {
      return 4;
    } else {
      return 2;
    }
  }

  double get childAspectRatio {
    if (screenWidth > 900) {
      return 0.7;
    } else if (screenWidth > 600) {
      return 0.8;
    } else {
      return 0.9;
    }
  }
}

extension RoutingExtensions on GlobalKey<NavigatorState> {
  dynamic get pop => currentState?.pop();

  dynamic push(Widget widget) => currentState?.push(
    MaterialPageRoute(
      builder: (_) => widget,
      settings: RouteSettings(name: widget.runtimeType.toString()),
    ),
  );

  dynamic pushReplacement(Widget widget) => currentState?.pushReplacement(
    MaterialPageRoute(
      builder: (_) => widget,
      settings: RouteSettings(name: widget.runtimeType.toString()),
    ),
  );

  dynamic pushAndRemovePreviousRoutes(Widget widget) =>
      currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => widget,
          settings: RouteSettings(name: widget.runtimeType.toString()),
        ),
        (_) => false,
      );
}

extension BuildContextPaddingExtensions on BuildContext {
  EdgeInsets all(double value) => EdgeInsets.all(value.r);

  EdgeInsets horizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value.r);

  EdgeInsets vertical(double value) =>
      EdgeInsets.symmetric(vertical: value.r);

  EdgeInsets symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: horizontal.r,
      vertical: vertical.r,
    );
  }

  EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: left.r,
      top: top.r,
      right: right.r,
      bottom: bottom.r,
    );
  }

  EdgeInsetsDirectional directionalOnly({
    double start = 0,
    double top = 0,
    double end = 0,
    double bottom = 0,
  }) {
    return EdgeInsetsDirectional.only(
      start: start.r,
      top: top.r,
      end: end.r,
      bottom: bottom.r,
    );
  }
}