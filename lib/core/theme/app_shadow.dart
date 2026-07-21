import 'package:flutter/material.dart';

class AppShadow {
  static List<BoxShadow> btnInnerTop = [
    BoxShadow(
      color: const Color(0xFF7E7E7E).withOpacity(0.3),
      blurRadius: 0,
      offset: const Offset(0, -4),
      spreadRadius: 0,
      blurStyle: BlurStyle.inner,
    ),
  ];

  static List<BoxShadow> btnInnerBottom = [
    BoxShadow(
      color: const Color(0xFFEEF5FF),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 2,
      blurStyle: BlurStyle.inner,
    ),
  ];

  static List<BoxShadow> btnDropWhite = [
    BoxShadow(
      color: const Color(0xFFFFFFFF),
      blurRadius: 0,
      offset: const Offset(0, 0),
      spreadRadius: 5,
    ),
  ];

  static List<BoxShadow> btnDropLight = [
    BoxShadow(
      color: const Color(0xFFEEF5FF),
      blurRadius: 0,
      offset: const Offset(0, 0),
      spreadRadius: 4,
    ),
  ];

  static List<BoxShadow> btnDropGrey = [
    BoxShadow(
      color: const Color(0xFFD7D7D7),
      blurRadius: 0,
      offset: const Offset(0, 0),
      spreadRadius: 4,
    ),
  ];

  static List<BoxShadow> btnWithInnerBottom = [
    BoxShadow(
      color: const Color(0xFF7E7E7E).withOpacity(0.3),
      blurRadius: 0,
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      color: const Color(0xFFEEF5FF),
      blurRadius: 4,
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(color: const Color(0xFFFFFFFF), blurRadius: 0),
    BoxShadow(color: const Color(0xFFEEF5FF), blurRadius: 0),
  ];

  static List<BoxShadow> btnWithoutInnerBottom = [
    BoxShadow(
      color: const Color(0xFF7E7E7E).withOpacity(0.3),
      blurRadius: 0,
      offset: const Offset(0, -4),
      spreadRadius: 0,
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      color: const Color(0xFFFFFFFF),
      blurRadius: 0,
      offset: const Offset(0, 0),
      spreadRadius: 5,
    ),
    BoxShadow(
      color: const Color(0xFFEEF5FF),
      blurRadius: 0,
      offset: const Offset(0, 0),
      spreadRadius: 4,
    ),
  ];

  static List<BoxShadow> btnWithGreyDrop = [
    BoxShadow(
      color: const Color(0xFF7E7E7E).withOpacity(0.3),
      blurRadius: 0,
      offset: const Offset(0, -4),
      spreadRadius: 0,
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      color: const Color(0xFFFFFFFF),
      blurRadius: 0,
      offset: const Offset(0, 0),
      spreadRadius: 5,
    ),
    BoxShadow(
      color: const Color(0xFFD7D7D7),
      blurRadius: 0,
      offset: const Offset(0, 0),
      spreadRadius: 4,
    ),
  ];
}
