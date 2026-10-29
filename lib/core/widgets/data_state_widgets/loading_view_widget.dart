part of '../widgets.dart';

class LoadingViewWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;
  const LoadingViewWidget({super.key, this.message, this.color, this.size});

  @override
  Widget build(BuildContext context) => AppLoadingState(
    message: message,
    compact: size != null,
    color: color,
  );
}
