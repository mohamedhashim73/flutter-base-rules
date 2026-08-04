import 'package:flutter/material.dart';
import 'package:playx/playx.dart';
import 'package:base/core/widgets/btn_widgets/close_icon_btn_widget.dart';
import 'package:base/core/constants/constants.dart';
import 'package:base/core/theme/app_colors.dart';

class SheetActionBtnWidget extends StatelessWidget {
  final VoidCallback? onAction;

  const SheetActionBtnWidget({super.key, this.onAction});

  @override
  Widget build(BuildContext context) {
    if (onAction == null) return const CloseIconBtnWidget();

    return InkWell(
      onTap: onAction,
      child: Container(
        width: 38.r,
        height: 38.r,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white.withValues(alpha: 0.40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(47.r),
          ),
        ),
        child: Center(
          child: Icon(
            AppConstants.kPlatformIsIOS
                ? Icons.arrow_back_ios_new
                : Icons.arrow_back,
            color: AppColors.kDarkBlue,
            size: 20.r,
          ),
        ),
      ),
    );
  }
}
