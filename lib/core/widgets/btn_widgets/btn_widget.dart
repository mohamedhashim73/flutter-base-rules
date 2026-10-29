part of '../widgets.dart';

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
      child: Icon(
        iconData,
        size: size,
        color: color ?? context.colors.primary,
      ),
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
    final colors = context.colors;
    return MaterialButton(
      onPressed: isLoading != null && isLoading == true ? () {} : onTap,
      elevation: 0,
      splashColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      hoverColor: colors.primary.withValues(alpha: 0.06),
      focusColor: Colors.transparent,
      hoverElevation: 0,
      disabledElevation: 0,
      focusElevation: 0,
      height: height ?? AppSizes.controlHeight,
      minWidth: minWidth,
      disabledColor: AppColors.kDisabled,
      highlightElevation: 0,
      color: backgroundColor ?? colors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: radiusValue != null
            ? BorderRadius.circular(radiusValue!)
            : BorderRadius.circular(AppDesignRadius.control),
        side: BorderSide(color: borderColor ?? Colors.transparent),
      ),
      child: Align(
        alignment: Alignment.center,
        child: Builder(
          builder: (context) {
            if (isLoading != null && isLoading == true) {
              return SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: color ?? AppColors.kWhite,
                  strokeWidth: 2.2,
                ),
              );
            } else {
              if (widget != null) {
                return widget!;
              } else if (suffix != null || prefix != null) {
                return Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ?prefix,
                    Flexible(
                      child: Text(
                        title ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: onTap == null
                              ? colors.textSecondary
                              : color ?? AppColors.kWhite,
                          fontSize: txtSize ?? 13.5,
                        ),
                      ),
                    ),
                    ?suffix,
                  ],
                );
              } else {
                return Text(
                  title ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: onTap == null
                        ? colors.textSecondary
                        : color ?? AppColors.kWhite,
                    fontSize: txtSize ?? 13.5,
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
      height: height ?? AppSizes.controlHeight,
      minWidth: minWidth,
      highlightElevation: 0,
      splashColor: Colors.white.withValues(alpha: 0.08),
      color: withoutBackground != null
          ? Colors.transparent
          : backgroundColor ?? context.colors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: radiusValue != null
            ? BorderRadius.circular(radiusValue!)
            : BorderRadius.circular(AppDesignRadius.control),
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
          color: txtColor ?? context.colors.primary,
          fontSize: txtSize ?? 13,
        ),
      ),
    );
  }
}
