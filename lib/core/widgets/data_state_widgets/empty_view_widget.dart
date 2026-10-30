part of '../widgets.dart';

class EmptyViewWidget extends StatelessWidget {
  final bool isShorten;
  final String? message;
  final IconData? icon;

  const EmptyViewWidget({
    super.key,
    this.isShorten = false,
    this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => AppStateView(
    compact: isShorten,
    icon: icon ?? Icons.inbox_outlined,
    title: message ?? AppStrings.kNoDataFound,
    message: isShorten ? null : 'ستظهر السجلات هنا بمجرد إنشائها أو مزامنتها.',
  );
}
