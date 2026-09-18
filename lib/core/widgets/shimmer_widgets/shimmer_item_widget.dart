part of '../widgets.dart';

class ShimmerItemWidget extends StatelessWidget {
  final double? height;
  final double? width;
  final Color? color;
  final Widget? widget;
  final double? radius;
  final bool borderIsOn;
  const ShimmerItemWidget({
    super.key,
    this.height,
    this.width,
    this.color,
    this.widget,
    this.radius,
    this.borderIsOn = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withOpacity(0.04),
        borderRadius: radius != null
            ? BorderRadius.circular(radius!)
            : AppDimensions.kMainRadius,
        border: borderIsOn ? AppDimensions.kMainBorder : null,
      ),
      child: widget,
    );
  }
}
