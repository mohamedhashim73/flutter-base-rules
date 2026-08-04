import 'package:base/core/widgets/data_state_widgets/toggle_between_widgets.dart';
import 'package:flutter/material.dart';
import 'package:playx/playx.dart';

class BtnRowContent extends StatelessWidget {
  final Widget? prefix;
  final Widget? suffix;
  final double? spacing;
  final String title;
  final Color color;
  final double txtSize;
  final FontWeight fontWeight;
  final MainAxisAlignment mainAxisAlignment;

  const BtnRowContent({
    super.key,
    this.prefix,
    this.suffix,
    required this.title,
    required this.color,
    required this.txtSize,
    required this.fontWeight,
    required this.mainAxisAlignment,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: spacing ?? 10.r,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        ?prefix,
        ConditionalFlexWidget(
          flexibleNotExpande: suffix == null,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: fontWeight,
              color: color,
              fontSize: txtSize,
            ),
          ),
        ),
        ?suffix,
      ],
    );
  }
}
