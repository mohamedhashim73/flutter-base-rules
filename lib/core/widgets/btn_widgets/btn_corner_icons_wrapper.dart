import 'package:base/core/theme/app_diemnsions.dart';
import 'package:flutter/material.dart';
import 'package:playx/playx.dart';
import 'package:base/core/services/base/asset_service.dart';

class BtnCornerIconsWrapper extends StatelessWidget {
  final Widget child;
  final bool? topCornerIcon;
  final bool? bottomCornerIcon;
  final bool showCornerIcons;
  final bool badgeIsOn;
  final double? space;

  const BtnCornerIconsWrapper({
    super.key,
    required this.child,
    this.topCornerIcon,
    this.bottomCornerIcon,
    required this.showCornerIcons,
    required this.badgeIsOn,
    this.space,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        child,
        if (topCornerIcon == true || showCornerIcons)
          Positioned(
            top: space ?? AppDimensions.btnCornerLSpace,
            left: space ?? AppDimensions.btnCornerLSpace,
            child: ImageViewer.svgAsset(
              Assets.icVector5,
              width: 24.r,
              fit: BoxFit.fill,
              height: 16.r,
            ),
          ),
        if (bottomCornerIcon == true || showCornerIcons)
          Positioned(
            bottom: space ?? AppDimensions.btnCornerLSpace,
            right: space ?? AppDimensions.btnCornerLSpace,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(-1.0, -1.0, 1.0),
              child: ImageViewer.svgAsset(
                Assets.icVector5,
                width: 24.r,
                height: 16.r,
                fit: BoxFit.fill,
              ),
            ),
          ),
      ],
    );
  }
}
