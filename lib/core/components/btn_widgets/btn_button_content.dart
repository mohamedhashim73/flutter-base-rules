import 'package:flutter/material.dart';
import 'package:base/core/theme/app_colors.dart';
import 'btn_loading_indicator.dart';
import 'btn_row_content.dart';
import 'btn_text_content.dart';

class BtnButtonContent extends StatelessWidget {
  final bool? isLoading;
  final bool keepTxtEvenLoading;
  final Widget? widget;
  final Widget? suffix;
  final Widget? prefix;
  final String title;
  final Color color;
  final double? rowSpacing;
  final double txtSize;
  final FontWeight fontWeight;
  final MainAxisAlignment mainAxisAlignment;
  final bool isDisabled;

  const BtnButtonContent({
    super.key,
    this.isLoading,
    required this.keepTxtEvenLoading,
    this.widget,
    this.suffix,
    this.prefix,
    required this.title,
    required this.color,
    required this.txtSize,
    required this.fontWeight,
    required this.mainAxisAlignment,
    required this.isDisabled,
    this.rowSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = isDisabled ? AppColors.kSecondary : color;

    if (isLoading == true && !keepTxtEvenLoading) {
      return BtnLoadingIndicator(color: color);
    }

    if (widget != null) {
      return widget!;
    }

    if (suffix != null || prefix != null) {
      return BtnRowContent(
        prefix: prefix,
        suffix: suffix,
        title: title,
        spacing: rowSpacing,
        color: effectiveColor,
        txtSize: txtSize,
        fontWeight: fontWeight,
        mainAxisAlignment: mainAxisAlignment,
      );
    }

    return BtnTextContent(
      title: title,
      color: effectiveColor,
      txtSize: txtSize,
      fontWeight: fontWeight,
    );
  }
}
