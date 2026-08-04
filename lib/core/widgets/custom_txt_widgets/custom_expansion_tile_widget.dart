import 'package:base/core/extensions/buildContext_extensions.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CustomExpansionListTileWidget extends StatelessWidget {
  final String title;
  final String? subTitle;
  final List<Widget> children;
  const CustomExpansionListTileWidget({
    super.key,
    this.subTitle,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.kWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: context.main,
        side: BorderSide(
          color: AppColors.kSecondary.withOpacity(0.12),
          width: 0.89,
        ),
      ),
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
        iconColor: AppColors.kPrimary,
        dense: true,
        subtitle: subTitle == null
            ? null
            : Text(
                "$subTitle",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.kSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
        shape: RoundedRectangleBorder(
          borderRadius: context.main,
          side: BorderSide(
            color: AppColors.kSecondary.withOpacity(0.12),
            width: 0.89,
          ),
        ),
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.kPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: children,
      ),
    );
  }
}

// TODO: Un Comment
// class ShimmerExpansionTileWidget extends StatelessWidget {
//   const ShimmerExpansionTileWidget({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: context.thirdCard,
//       elevation: 0,
//       shape: RoundedRectangleBorder(borderRadius: context.min, side: AppConstants.kIsDark ? BorderSide.none : const BorderSide(color: Color(0xffF1F5F7))),
//       margin: EdgeInsets.zero,
//       child: ExpansionTile(
//           tilePadding: const EdgeInsets.symmetric(horizontal: 14),
//           childrenPadding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
//           iconColor: context.main,
//           trailing: ShimmerWidget(height: 14,width: 14,radius: 2,),
//           shape: RoundedRectangleBorder(borderRadius: context.min, side: AppConstants.kIsDark ? BorderSide.none : const BorderSide(color: Color(0xffF1F5F7))),
//           title: ShimmerWidget(height: 10,)
//       ),
//     );
//   }
// }
