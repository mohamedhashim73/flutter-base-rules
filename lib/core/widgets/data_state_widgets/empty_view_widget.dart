part of '../widgets.dart';

class EmptyViewWidget extends StatelessWidget {
  final bool isShorten;

  const EmptyViewWidget({super.key, this.isShorten = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: context.paddingZero,
        children: [
          SizedBox(
            height: null,
            width: null,
            child: Center(child: CustomImage(Assets.empty)),
          ),
          Text(
            AppStrings.kNoDataFound,
            style: TextStyle(
              color: Color(0xff353A62),
              fontSize: (isShorten ? 12 : 24).sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).marginOnly(top: (isShorten ? 16 : 24).r),
        ],
      ),
    );
  }
}
