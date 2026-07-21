import 'package:flutter/material.dart';
import 'package:playx/playx.dart';

class PriceRowWidget extends StatelessWidget {
  final String priceText;
  final String? oldPriceText;
  final double priceSize;
  final double oldPriceSize;

  const PriceRowWidget({
    super.key,
    required this.priceText,
    this.oldPriceText,
    this.priceSize = 16,
    this.oldPriceSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 8.r,
      children: [
        Flexible(
          child: Text(
            priceText,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFF07B7FA),
              fontSize: priceSize.sp,
              fontWeight: FontWeight.w700,
              height: 1.38,
            ),
          ),
        ),
        if (oldPriceText != null)
          Flexible(
            child: Text(
              oldPriceText!,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: const Color(0xFF869499),
                fontSize: oldPriceSize.sp,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.lineThrough,
                height: 2,
              ),
            ),
          ),
      ],
    );
  }
}
