import 'package:flutter/material.dart';

class BtnTextContent extends StatelessWidget {
  final String title;
  final Color color;
  final double txtSize;
  final FontWeight fontWeight;

  const BtnTextContent({
    super.key,
    required this.title,
    required this.color,
    required this.txtSize,
    required this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(fontWeight: fontWeight, color: color, fontSize: txtSize),
    );
  }
}
