part of '../widgets.dart';

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
              CustomImage(
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
