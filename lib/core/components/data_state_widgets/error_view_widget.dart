import 'package:base/core/constants/strings.dart';
import 'package:playx/playx.dart';
import 'package:base/core/components/custom_image_widget/custom_image.dart';
import 'package:base/core/constants/extensions/buildContext_extensions.dart';
import 'package:base/core/constants/extensions/int_extensions.dart';
import 'package:base/core/services/base/asset_service.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ErrorViewWidget extends StatelessWidget {
  final Function()? retryFunction;
  final double? size;
  final double? txtSize;
  final String? message;
  final FontWeight? txtWeight;
  final bool isShorten;

  const ErrorViewWidget({
    super.key,
    this.retryFunction,
    this.size,
    this.txtSize,
    this.txtWeight,
    this.message,
    this.isShorten = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.cardPadding,
      child: Center(
        child: InkWell(
          onTap: retryFunction,
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              MyImage(
                Assets.error,
                imgHeight: (isShorten ? 74 : size) ?? 200.r,
                imgWidth: (isShorten ? 74 : size) ?? 200.r,
              ),
              (isShorten ? 10 : 22).vrSpace,
              Text(
                message ?? AppStrings.kSomethingWentWrong,
                style: TextStyle(
                  color: AppColors.kMainTxt,
                  fontSize: (isShorten ? 12 : txtSize ?? 14).sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
