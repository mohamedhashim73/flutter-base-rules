part of '../widgets.dart';

class EmptyViewWidget extends StatelessWidget {
  final EmptyType? type;
  final bool isShorten;

  const EmptyViewWidget({super.key, this.type, this.isShorten = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: context.paddingZero,
        children: [
          SizedBox(
            height: type?.image != null ? 234.r : null,
            width: type?.image != null ? 234.r : null,
            child: Center(child: CustomImage(type?.image ?? Assets.empty)),
          ),
          Text(
            type?.name ?? AppStrings.kNoDataFound,
            style: TextStyle(
              color: Color(0xff353A62),
              fontSize: (isShorten ? 12 : 24).sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).marginOnly(
            top: (isShorten ? 16 : 24).r,
            bottom: type?.description != null ? 8.r : 0,
          ),
          if (type?.description != null)
            Text(
              "${type?.description}",
              style: TextStyle(
                color: Color(0xff9E9E9E),
                fontSize: (isShorten ? 12 : 14).sp,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
