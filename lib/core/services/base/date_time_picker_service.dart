part of '../services.dart';

class DateTimePickerService {
  static Future<DateTime?> pickDate({
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return _showDatePicker(
      AppRoutes.key.currentContext!,
      initialDate ?? DateTime.now(),
      firstDate ?? DateTime(2000),
      lastDate ?? DateTime(DateTime.now().year + 5),
    );
  }

  static Future<DateTime?> _showDatePicker(
    BuildContext context,
    DateTime initial,
    DateTime first,
    DateTime last,
  ) async {
    DateTime selectedDate = initial;
    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.colors;
        return AppDialog(
          title: 'اختيار التاريخ',
          maxWidth: 420,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          actions: [
            BtnWidget(
              title: 'تأكيد',
              onTap: () => Navigator.of(dialogContext).pop(selectedDate),
            ),
            BtnWidget(
              title: 'إلغاء',
              onTap: () => Navigator.of(dialogContext).pop(),
              backgroundColor: colors.card,
              borderColor: colors.border,
              color: colors.onSurface,
            ),
          ],
          child: Theme(
            data: Theme.of(dialogContext).copyWith(
              colorScheme: Theme.of(dialogContext).colorScheme.copyWith(
                primary: colors.primary,
                onPrimary: Colors.white,
                onSurface: colors.onSurface,
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
        );
      },
    );
  }
}
