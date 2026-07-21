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
    return InkWell(
      onTap: onTap,
      child: Icon(iconData, size: size, color: color ?? AppColors.kMain),
    );
  }
}
