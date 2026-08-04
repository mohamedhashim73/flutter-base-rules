import 'package:base/core/theme/app_colors.dart';
import 'package:base/core/theme/app_diemnsions.dart';
import 'package:flutter/material.dart';
import 'package:playx/playx.dart';
import 'btn_button_content.dart';
import 'btn_inkwell_button.dart';

class BtnWidget extends StatelessWidget {
  final Function()? onTap;
  final Widget? suffix;
  final Widget? prefix;
  final Widget? widget;
  final Color? borderColor;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? color;
  final double? radiusValue;
  final double? minWidth;
  final double? txtSize;
  final double? height;
  final String? title;
  final double? cornerSpace;
  final bool? isLoading;
  final MainAxisAlignment? mainAxisAlignment;
  final bool showCornerIcons;
  final bool? topCornerIcon;
  final bool? bottomCornerIcon;
  final FontWeight? fontWeight;
  final bool defaultHeight;
  final bool keepTxtEvenLoading;
  final List<BoxShadow>? shadows;
  final bool defaultShadowIsOn;
  final String? badgeTxt;
  final Color? badgeTxtColor;
  final double? badgeStart;
  final double? badgeEnd;
  final EdgeInsetsGeometry? badgePadding;
  final double? badgeTxtSize;
  final double? badgeBorderRadius;
  final bool badgeHalfOutside;
  final double? rowSpacing;
  final bool isBadgeUpperStartNotEnd;

  const BtnWidget({
    super.key,
    this.onTap,
    this.minWidth,
    this.prefix,
    this.borderColor,
    this.radiusValue,
    this.height,
    this.defaultHeight = false,
    this.defaultShadowIsOn = true,
    this.keepTxtEvenLoading = false,
    this.title,
    this.backgroundColor,
    this.color,
    this.isLoading,
    this.suffix,
    this.widget,
    this.txtSize,
    this.padding,
    this.showCornerIcons = false,
    this.topCornerIcon,
    this.bottomCornerIcon,
    this.fontWeight,
    this.shadows,
    this.mainAxisAlignment,
    this.badgeTxt,
    this.badgeTxtColor,
    this.badgeStart,
    this.badgePadding,
    this.badgeTxtSize,
    this.badgeBorderRadius,
    this.badgeHalfOutside = true,
    this.isBadgeUpperStartNotEnd = false,
    this.badgeEnd,
    this.cornerSpace,
    this.rowSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasCornerIcons =
        showCornerIcons || topCornerIcon == true || bottomCornerIcon == true;

    final EdgeInsets contentPadding = padding ?? AppDimensions.btnSPadding;

    final double borderRadius = radiusValue ?? 70.r;

    final Widget buttonContent = BtnButtonContent(
      isLoading: isLoading,
      keepTxtEvenLoading: keepTxtEvenLoading,
      widget: widget,
      rowSpacing: rowSpacing,
      suffix: suffix,
      prefix: prefix,
      title: title ?? '',
      color: color ?? AppColors.kWhite,
      txtSize: txtSize ?? 16.sp,
      fontWeight: fontWeight ?? FontWeight.bold,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.center,
      isDisabled: onTap == null,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        BtnInkWellButton(
          onTap: isLoading == true ? null : onTap,
          contentPadding: contentPadding,
          hasCornerIcons: hasCornerIcons,
          borderRadius: borderRadius,
          defaultShadowIsOn: defaultShadowIsOn,
          minWidth: minWidth,
          height: height,
          defaultHeight: defaultHeight,
          backgroundColor: backgroundColor ?? AppColors.kMain,
          borderColor: borderColor,
          isDisabled: onTap == null,
          topCornerIcon: topCornerIcon,
          badgeIsOn: badgeTxt != null,
          bottomCornerIcon: bottomCornerIcon,
          showCornerIcons: showCornerIcons,
          shadows: shadows,
          cornerSpace: cornerSpace,
          child: buttonContent,
        ),
      ],
    );
  }
}
