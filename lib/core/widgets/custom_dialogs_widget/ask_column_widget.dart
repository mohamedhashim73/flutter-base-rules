part of '../widgets.dart';

class AskColumnWidget extends StatelessWidget {
  final Function()? okTap;
  final String content;
  final bool btnIsVisible;
  final Widget? body;
  final bool outImmediatelyCallOk;
  const AskColumnWidget({
    super.key,
    this.outImmediatelyCallOk = true,
    this.btnIsVisible = true,
    this.okTap,
    required this.content,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child:
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 14,
            children: [
              Text(
                content,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.kMainTxt,
                ),
              ),
              if (body != null) Flexible(child: body!),
              Visibility(
                visible: btnIsVisible,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 14,
                  children: [
                    TextBtnWidget(
                      onTap: () {
                        if (outImmediatelyCallOk) {
                          AppRoutes.key.pop;
                        }
                        if (okTap != null) {
                          okTap!();
                        }
                      },
                      title: "متابعة",
                      txtColor: AppColors.kMain,
                    ),
                    TextBtnWidget(
                      onTap: () => AppRoutes.key.pop,
                      title: "إلغاء",
                      txtColor: AppColors.kRed,
                    ),
                  ],
                ),
              ),
            ],
          ).paddingOnly(
            left: 14,
            right: 14,
            bottom: context.concatenatePaddingOnBottom(14),
          ),
    );
  }
}
