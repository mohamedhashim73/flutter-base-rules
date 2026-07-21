import 'package:playx/playx.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SwitchTileWidget extends StatelessWidget {
  final bool isOn;
  final String title;
  final Function()? onTap;
  const SwitchTileWidget({
    super.key,
    required this.isOn,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        spacing: 10,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.kPrimary,
              ),
            ),
          ),
          // SvgPicture.asset(isOn ? AssetsService.icSwitchOn : AssetsService.icSwitchOff,height: 38,width: 38,),
        ],
      ).paddingSymmetric(vertical: 2),
    );
  }
}
