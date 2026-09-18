part of '../widgets.dart';

// import 'package:flutter/material.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
// import 'package:playx/playx.dart';
// import 'package:base/core/theme/app_colors.dart';

// class PinCodeTxtFieldWidget extends StatelessWidget {
//   final Function(String)? onCompleted;
//   final Function(String)? onChanged;
//   final int length;

//   const PinCodeTxtFieldWidget({
//     super.key,
//     this.onCompleted,
//     this.onChanged,
//     this.length = 6,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.ltr,
//       child: Center(
//         child: MaterialPinField(
//           length: length,
//           keyboardType: TextInputType.number,
//           autoFocus: true,
//           onCompleted: onCompleted,
//           enablePaste: true,
//           enableAutofill: true,
//           onChanged: onChanged,
//           theme: MaterialPinTheme(
//             shape: MaterialPinShape.outlined,
//             cellSize: Size(55.r, 70.r),
//             spacing: 10.r,
//             borderRadius: BorderRadius.circular(12.r),
//             borderWidth: 1,
//             focusedBorderWidth: 1,
//             fillColor: AppColors.kWhite,
//             focusedFillColor: AppColors.kPrimary,
//             filledFillColor: AppColors.kPrimary,
//             borderColor: const Color(0xFFE1E4EA),
//             focusedBorderColor: AppColors.kPrimary,
//             filledBorderColor: AppColors.kPrimary,
//             cursorColor: AppColors.kWhite,
//             followingFillColor: AppColors.kWhite,
//             followingBorderColor: const Color(0xFFE1E4EA),
//             textStyle: TextStyle(
//               color: AppColors.kWhite,
//               fontSize: 20.sp,
//               fontWeight: FontWeight.w700,
//             ),
//             entryAnimation: MaterialPinAnimation.fade,
//           ),
//         ),
//       ),
//     );
//   }
// }
