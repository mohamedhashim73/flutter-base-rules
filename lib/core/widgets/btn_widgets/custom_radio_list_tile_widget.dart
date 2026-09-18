part of '../widgets.dart';

// import 'package:flutter/material.dart';
// import '../../theme/app_colors.dart';

// class CustomRadioListTileWidget extends StatelessWidget {
//   final Function()? onTap;
//   final bool isSelected;
//   final String? label;
//   const CustomRadioListTileWidget({
//     super.key,
//     required this.onTap,
//     required this.isSelected,
//     required this.label,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Row(
//         spacing: 10,
//         children: [
//           Icon(
//             isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
//             color: isSelected ? AppColors.kMain : AppColors.kBlueGrey,
//           ),
//           Text(
//             "$label",
//             style: TextStyle(
//               color: isSelected ? AppColors.kMain : AppColors.kBlueGrey,
//               fontSize: 14,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
