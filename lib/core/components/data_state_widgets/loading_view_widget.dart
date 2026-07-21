import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/constants.dart';
import '../../theme/app_colors.dart';
import 'toggle_between_widgets.dart';

class LoadingViewWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;
  const LoadingViewWidget({super.key, this.message, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: WidgetSwitcher(
        isFirst: AppConstants.kPlatformIsIOS,
        first: CupertinoActivityIndicator(
          color: color ?? AppColors.kSecondary,
          radius: (size != null ? size! - 6 : 16).r,
        ),
        second: SizedBox(
          height: (size ?? 22).r,
          width: (size ?? 22).r,
          child: CircularProgressIndicator(
            strokeWidth: 2.4.r,
            color: color ?? AppColors.kSecondary,
          ),
        ),
      ),
    );
  }
}
