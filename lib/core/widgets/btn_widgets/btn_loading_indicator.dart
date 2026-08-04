import 'package:flutter/material.dart';

class BtnLoadingIndicator extends StatelessWidget {
  final Color color;

  const BtnLoadingIndicator({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      width: 26,
      child: CircularProgressIndicator(color: color, strokeWidth: 2.4),
    );
  }
}
