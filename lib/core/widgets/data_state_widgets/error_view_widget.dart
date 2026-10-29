part of '../widgets.dart';

class ErrorViewWidget extends StatelessWidget {
  final Function()? retryFunction;
  final double? size;
  final double? txtSize;
  final String? message;
  final FontWeight? txtWeight;
  final bool isShorten;
  final IconData? icon;

  const ErrorViewWidget({
    super.key,
    this.retryFunction,
    this.size,
    this.txtSize,
    this.txtWeight,
    this.message,
    this.isShorten = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => AppStateView(
    compact: isShorten,
    icon: icon ?? Icons.cloud_off_outlined,
    tone: AppTone.danger,
    title: AppStrings.kSomethingWentWrong,
    message: message ?? 'تعذر تحميل البيانات. تحقق من الاتصال ثم أعد المحاولة.',
    action: retryFunction == null
        ? null
        : OutlinedButton.icon(
            onPressed: () => retryFunction!(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة المحاولة'),
          ),
  );
}
