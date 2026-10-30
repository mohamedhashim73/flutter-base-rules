part of '../widgets.dart';

Future<void> showAdaptiveDialogWidget({
  Widget? content,
  String? okTxt,
  required String title,
  bool popImmediate = true,
  Function()? okTap,
  bool Function()? beforeOk,
  String? cancelTxt,
  Function()? onInit,
  Function()? onDispose,
}) async {
  onInit?.call();
  await showDialog(
    context: AppRoutes.key.currentContext!,
    builder: (dialogContext) {
      final colors = dialogContext.colors;
      return AppDialog(
        title: title,
        actions: [
          BtnWidget(
            title: okTxt ?? 'تأكيد',
            onTap: () {
              if (beforeOk != null && !beforeOk()) return;
              if (popImmediate) Navigator.of(dialogContext).pop();
              okTap?.call();
            },
          ),
          BtnWidget(
            title: cancelTxt ?? 'إلغاء',
            onTap: () => Navigator.of(dialogContext).pop(),
            backgroundColor: colors.card,
            borderColor: colors.border,
            color: colors.onSurface,
          ),
        ],
        child: content ?? const SizedBox.shrink(),
      );
    },
  );
  await Future<void>.delayed(const Duration(milliseconds: 350));
  onDispose?.call();
}
