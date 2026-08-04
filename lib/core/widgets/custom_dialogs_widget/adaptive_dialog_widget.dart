import 'package:base/core/widgets/btn_widgets/btn_widget.dart';
import 'package:base/core/theme/app_colors.dart';
import 'package:base/core/theme/app_diemnsions.dart';
import 'package:playx/playx.dart';
import 'package:base/core/constants/constants.dart';
import 'package:base/core/routes/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> showAdaptiveDialogWidget({
  Widget? content,
  String? okTxt,
  required String title,
  bool popImmediate = true,
  Function()? okTap,
  String? cancelTxt,
  Function()? onInit,
  Function()? onDispose,
}) async {
  onInit?.call();
  if (AppConstants.kPlatformIsIOS) {
    await showCupertinoDialog(
      context: AppRoutes.key.currentContext!,
      builder: (_) => _IOSDialogWidget(
        content: content,
        popImmediate: popImmediate,
        okTap: okTap,
        title: title,
        okTxt: okTxt,
        cancelTxt: cancelTxt,
      ),
    );
  } else {
    await showDialog(
      context: AppRoutes.key.currentContext!,
      builder: (_) => _AndroidDialogWidget(
        content: content,
        okTap: okTap,
        title: title,
        popImmediate: popImmediate,
        okTxt: okTxt,
        cancelTxt: cancelTxt,
      ),
    );
  }
  await Future<void>.delayed(const Duration(milliseconds: 350));
  onDispose?.call();
}

class _AndroidDialogWidget extends StatelessWidget {
  final Widget? content;
  final String? okTxt;
  final String title;
  final Function()? okTap;
  final bool popImmediate;
  final String? cancelTxt;
  const _AndroidDialogWidget({
    required this.title,
    this.content,
    this.okTxt,
    this.cancelTxt,
    this.popImmediate = true,
    this.okTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.main),
      backgroundColor: Colors.white,
      alignment: AlignmentDirectional.center,
      child: SizedBox(
        width: AppDimensions.dialogWidth,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child:
              Column(
                spacing: 16.r,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  ?content,
                  Row(
                    spacing: 16.r,
                    children: [
                      Expanded(
                        child: BtnWidget(
                          onTap: () {
                            if (popImmediate) {
                              Navigator.pop(context);
                            }
                            okTap?.call();
                          },
                          title: okTxt ?? 'تأكيد',
                        ),
                      ),
                      Expanded(
                        child: BtnWidget(
                          onTap: () => Navigator.pop(context),
                          title: cancelTxt ?? 'إلغاء',
                          backgroundColor: Colors.transparent,
                          borderColor: AppColors.kMain,
                          color: AppColors.kMain,
                        ),
                      ),
                    ],
                  ).paddingOnly(top: 8.r),
                ],
              ).paddingSymmetric(
                vertical: 24.r,
                horizontal: (context.isLandscape ? 24 : 16).r,
              ),
        ),
      ),
    );
  }
}

class _IOSDialogWidget extends StatelessWidget {
  final Widget? content;
  final String? okTxt;
  final String title;
  final Function()? okTap;
  final bool popImmediate;
  final String? cancelTxt;
  const _IOSDialogWidget({
    this.content,
    this.okTxt,
    required this.title,
    this.cancelTxt,
    this.popImmediate = true,
    this.okTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      content: Material(
        color: Colors.transparent,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 14,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              ?content,
            ],
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            if (popImmediate) {
              Navigator.pop(context);
            }
            okTap?.call();
          },
          child: Text(
            okTxt ?? 'تأكيد',
            style: TextStyle(
              color: AppColors.kMain,
              fontFamily: AppConstants.kMainFont,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            cancelTxt ?? 'إلغاء',
            style: TextStyle(
              color: AppColors.kMainTxt,
              fontFamily: AppConstants.kMainFont,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
