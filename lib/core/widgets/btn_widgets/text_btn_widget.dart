import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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
    return InkWell(
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
