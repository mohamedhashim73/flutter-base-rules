import 'package:flutter/material.dart';
import 'package:playx/playx.dart';
import 'package:base/core/theme/app_colors.dart';

class CloseIconBtnWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? color;
  final double? size;

  const CloseIconBtnWidget({super.key, this.onTap, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Icon(
        Icons.close,
        color: color ?? AppColors.kWhite,
        size: size ?? 24.r,
      ),
    );
  }
}
