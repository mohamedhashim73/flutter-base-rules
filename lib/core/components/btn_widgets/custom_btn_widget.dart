import 'package:flutter/material.dart';
import '../../constants/constants.dart';
import '../../theme/app_colors.dart';

class CustomBtnWidget extends StatelessWidget {
  final Function() onTap;
  final Color? borderColor;
  final double? radiusValue;
  final double? minWidth;
  final double? height;
  final Widget widget;
  final Color? backgroundColor;
  final bool? withoutBackground;

  const CustomBtnWidget({
    super.key,
    required this.onTap,
    this.minWidth,
    this.borderColor,
    this.radiusValue,
    this.height,
    this.withoutBackground,
    required this.widget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onTap,
      elevation: 0,
      height: height ?? 46,
      minWidth: minWidth,
      highlightElevation: 0,
      splashColor: Colors.transparent,
      color: withoutBackground != null
          ? Colors.transparent
          : backgroundColor ?? AppColors.kMain,
      shape: RoundedRectangleBorder(
        borderRadius: radiusValue != null
            ? BorderRadius.circular(radiusValue!)
            : AppConstants.kMainRadius,
        side: BorderSide(color: borderColor ?? Colors.transparent),
      ),
      child: widget,
    );
  }
}
