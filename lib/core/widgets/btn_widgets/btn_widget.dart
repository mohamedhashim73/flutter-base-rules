import 'package:base/core/theme/app_diemnsions.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class IconBtnWidget extends StatelessWidget {
  final IconData iconData;
  final Function() onTap;
  final Color? color;
  final double? size;
  const IconBtnWidget({
    super.key,
    required this.iconData,
    required this.onTap,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(iconData, size: size, color: color ?? AppColors.kMain),
    );
  }
}

class BtnWidget extends StatelessWidget {
  final Function()? onTap;
  final Widget? suffix;
  final Widget? prefix;
  final Widget? widget;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? color;
  final double? radiusValue;
  final double? minWidth;
  final double? txtSize;
  final double? height;
  final String? title;
  final bool? isLoading;
  const BtnWidget({
    super.key,
    this.onTap,
    this.minWidth,
    this.prefix,
    this.borderColor,
    this.radiusValue,
    this.height,
    this.title,
    this.backgroundColor,
    this.color,
    this.isLoading,
    this.suffix,
    this.widget,
    this.txtSize,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: isLoading != null && isLoading == true ? () {} : onTap,
      elevation: 0,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverElevation: 0,
      disabledElevation: 0,
      focusElevation: 0,
      height: height ?? 46,
      minWidth: minWidth,
      disabledColor: onTap == null ? AppColors.kDisabled : null,
      highlightElevation: 0,
      color: backgroundColor ?? AppColors.kMain,
      shape: RoundedRectangleBorder(
        borderRadius: radiusValue != null
            ? BorderRadius.circular(radiusValue!)
            : AppDimensions.kMainRadius,
        side: BorderSide(color: borderColor ?? Colors.transparent),
      ),
      child: Align(
        alignment: Alignment.center,
        child: Builder(
          builder: (context) {
            if (isLoading != null && isLoading == true) {
              return SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(
                  color: color ?? AppColors.kWhite,
                  strokeWidth: 2.4,
                ),
              );
            } else {
              if (widget != null) {
                return widget!;
              } else if (suffix != null || prefix != null) {
                return Row(
                  spacing: 10,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ?prefix,
                    Flexible(
                      child: Text(
                        title ?? "",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: onTap == null
                              ? AppColors.kSecondary
                              : color ?? AppColors.kWhite,
                          fontSize: txtSize ?? 14,
                        ),
                      ),
                    ),
                    ?suffix,
                  ],
                );
              } else {
                return Text(
                  title ?? "",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: onTap == null
                        ? AppColors.kSecondary
                        : color ?? AppColors.kWhite,
                    fontSize: txtSize ?? 14,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

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
            : AppDimensions.kMainRadius,
        side: BorderSide(color: borderColor ?? Colors.transparent),
      ),
      child: widget,
    );
  }
}

class TextBtnWidget extends StatelessWidget {
  final String title;
  final Function() onTap;
  final Color? txtColor;
  final double? txtSize;
  const TextBtnWidget({
    super.key,
    required this.title,
    required this.onTap,
    this.txtColor,
    this.txtSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: txtColor ?? AppColors.kBlack,
          fontSize: txtSize ?? 14,
        ),
      ),
    );
  }
}
