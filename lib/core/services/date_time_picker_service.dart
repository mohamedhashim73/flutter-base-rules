import 'package:base/core/constants/constants.dart';
import 'package:base/core/extensions/buildContext_extensions.dart';
import 'package:base/core/routes/routes.dart';
import 'package:base/core/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DateTimePickerService {
  static Future<DateTime?> pickDate({
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    if (AppConstants.kPlatformIsIOS) {
      return _showIOSPicker(
        AppRoutes.key.currentContext!,
        initialDate ?? DateTime.now(),
        firstDate ?? DateTime(2000),
        lastDate ?? DateTime(DateTime.now().year + 5),
      );
    } else {
      return _showMaterialPicker(
        AppRoutes.key.currentContext!,
        initialDate ?? DateTime.now(),
        firstDate ?? DateTime(2000),
        lastDate ?? DateTime(DateTime.now().year + 5),
      );
    }
  }

  // ================= IOS =================
  static Future<DateTime?> _showIOSPicker(
    BuildContext context,
    DateTime initial,
    DateTime first,
    DateTime last,
  ) async {
    DateTime selectedDate = initial;
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            _IOSHeader(
              onCancel: () => Navigator.pop(context),
              onDone: () => Navigator.pop(context, selectedDate),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                minimumDate: first,
                maximumDate: last,
                onDateTimeChanged: (date) {
                  selectedDate = date;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<DateTime?> _showMaterialPicker(
    BuildContext context,
    DateTime initial,
    DateTime first,
    DateTime last,
  ) async {
    DateTime selectedDate = initial;
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: context.main,
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.kMain,
                      onPrimary: Colors.white,
                      onSurface: AppColors.kMainTxt,
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: initial,
                    firstDate: first,
                    lastDate: last,
                    onDateChanged: (date) {
                      selectedDate = date;
                    },
                  ),
                ),
                const Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, selectedDate);
                      },
                      child: Text(
                        "Confirm",
                        style: TextStyle(
                          color: AppColors.kMain,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppColors.kMainTxt,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IOSHeader extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onDone;
  const _IOSHeader({required this.onCancel, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onDone,
            child: Text(
              "Confirm",
              style: TextStyle(
                color: AppColors.kMain,
                fontFamily: AppConstants.kMainFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onCancel,
            child: Text(
              "Cancel",
              style: TextStyle(
                color: AppColors.kMainTxt,
                fontFamily: AppConstants.kMainFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
