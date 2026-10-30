part of '../widgets.dart';

/// Shared dialog frame used across the application.
///
/// Keeps the title and action bar fixed while the content scrolls, so long
/// forms remain usable on short phone viewports.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.maxWidth = 560,
    this.showClose = true,
    this.contentPadding = const EdgeInsets.all(AppSpacing.xl),
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final bool showClose;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final media = MediaQuery.sizeOf(context);
    final width = media.width > maxWidth + 32 ? maxWidth : media.width - 32;
    final maxHeight = media.height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SizedBox(
          width: width,
          child: AppSurface(
            radius: AppDesignRadius.dialog,
            shadow: AppShadow.floating,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                  ),
                  child: Row(
                    spacing: AppSpacing.xs,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      if (showClose)
                        IconButton(
                          tooltip: 'إغلاق',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.divider),
                Flexible(
                  child: SingleChildScrollView(
                    padding: contentPadding,
                    child: child,
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  Divider(height: 1, color: colors.divider),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (actions.length == 1) {
                          return Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: actions.single,
                          );
                        }
                        if (constraints.maxWidth < 280) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: AppSpacing.sm,
                            children: actions,
                          );
                        }
                        return Row(
                          spacing: AppSpacing.sm,
                          children: [
                            for (final action in actions)
                              Expanded(child: action),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a design-system dialog with a title, scrollable content, and actions.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  List<Widget> actions = const [],
  double maxWidth = 560,
  bool showClose = true,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AppDialog(
      title: title,
      actions: actions,
      maxWidth: maxWidth,
      showClose: showClose,
      child: child,
    ),
  );
}

/// Prompts for a short text value using the shared dialog frame.
Future<String?> showAppPromptDialog({
  required BuildContext context,
  required String title,
  required String label,
  String confirmText = 'تأكيد',
  String cancelText = 'إلغاء',
  String? hintText,
  String? initialValue,
  bool multiline = true,
  TextInputType? keyboardType,
}) async {
  final controller = TextEditingController(text: initialValue);
  final colors = context.colors;
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AppDialog(
      title: title,
      actions: [
        BtnWidget(
          title: confirmText,
          onTap: () => Navigator.of(dialogContext).pop(controller.text.trim()),
        ),
        BtnWidget(
          title: cancelText,
          onTap: () => Navigator.of(dialogContext).pop(),
          backgroundColor: colors.card,
          borderColor: colors.border,
          color: colors.onSurface,
        ),
      ],
      child: TextField(
        controller: controller,
        autofocus: true,
        maxLines: multiline ? 3 : 1,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hintText),
      ),
    ),
  );
  controller.dispose();
  return result == null || result.isEmpty ? null : result;
}
