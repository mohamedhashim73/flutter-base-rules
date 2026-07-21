import 'package:base/core/theme/app_shadow.dart';
import 'package:base/core/theme/diemnsions.dart';
import 'package:flutter/material.dart';
import 'package:base/core/theme/app_colors.dart';
import 'btn_corner_icons_wrapper.dart';

class BtnInkWellButton extends StatelessWidget {
  final VoidCallback? onTap;
  final EdgeInsets contentPadding;
  final bool hasCornerIcons;
  final double borderRadius;
  final double? minWidth;
  final double? height;
  final bool badgeIsOn;
  final bool defaultHeight;
  final Color backgroundColor;
  final Color? borderColor;
  final bool isDisabled;
  final Widget child;
  final bool? topCornerIcon;
  final bool? bottomCornerIcon;
  final double? cornerSpace;
  final bool showCornerIcons;
  final bool defaultShadowIsOn;
  final List<BoxShadow>? shadows;

  const BtnInkWellButton({
    super.key,
    this.onTap,
    required this.contentPadding,
    required this.hasCornerIcons,
    required this.borderRadius,
    this.minWidth,
    this.height,
    required this.defaultHeight,
    required this.backgroundColor,
    this.borderColor,
    required this.isDisabled,
    required this.child,
    this.topCornerIcon,
    this.bottomCornerIcon,
    required this.showCornerIcons,
    this.shadows,
    required this.defaultShadowIsOn,
    required this.badgeIsOn,
    this.cornerSpace,
  });

  @override
  Widget build(BuildContext context) {
    // 1. نقوم ببناء محتوى زر الـ Container الأساسي أولاً
    Widget buttonContainer = Container(
      height: defaultHeight ? Dim.btnHeight : height,
      constraints: minWidth != null
          ? BoxConstraints(minWidth: minWidth!)
          : null,
      padding: contentPadding,
      decoration: BoxDecoration(
        color: isDisabled ? AppColors.kDisabled : backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? Colors.transparent),
        boxShadow:
            shadows ??
            (defaultShadowIsOn ? AppShadow.btnWithInnerBottom : null),
      ),
      child: Center(
        child: child,
      ), // هنا جعلنا الـ child مباشرة داخل الـ Container
    );

    // 2. الآن نتحقق إذا كان الزر يحتاج كورنرات، نغلف الـ Container بالكامل وليس الـ child الداخلي
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: hasCornerIcons
          ? BtnCornerIconsWrapper(
              topCornerIcon: topCornerIcon,
              bottomCornerIcon: bottomCornerIcon,
              space: cornerSpace,
              showCornerIcons: showCornerIcons,
              badgeIsOn: badgeIsOn,
              child: buttonContainer, // تغليف الـ Container بالكامل!
            )
          : buttonContainer,
    );
  }
}
