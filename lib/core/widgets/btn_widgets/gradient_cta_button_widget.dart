import 'package:base/core/theme/app_gradients.dart';
import 'package:base/core/theme/app_diemnsions.dart';
import 'package:flutter/material.dart';
import 'package:base/core/widgets/btn_widgets/btn_widget.dart';
import 'package:base/core/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GradientCtaButtonWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? height;
  final bool showCornerIcons;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? backgroundColor;
  final String? badgeTxt;
  final Color? disabledBackgroundColor;
  final Gradient? gradient;
  final EdgeInsets? padding;

  const GradientCtaButtonWidget({
    super.key,
    required this.title,
    this.onTap,
    this.isLoading = false,
    this.height,
    this.showCornerIcons = true,
    this.fontSize = 20,
    this.fontWeight = FontWeight.w700,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.gradient,
    this.badgeTxt,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: AppDimensions.gradientPageBtn,
      decoration: BoxDecoration(gradient: gradient ?? AppGradients.basic),
      child: BtnWidget(
        title: title,
        showCornerIcons: showCornerIcons,
        onTap: onTap,
        badgeTxt: badgeTxt,
        isLoading: isLoading,
        padding: padding ?? EdgeInsets.all(18.r),
        backgroundColor: onTap == null
            ? (disabledBackgroundColor ?? AppColors.kDisabled)
            : (backgroundColor ?? AppColors.kMain),
        txtSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
