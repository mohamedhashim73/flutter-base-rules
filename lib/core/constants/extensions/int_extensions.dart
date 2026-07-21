import 'package:flutter/material.dart';
import 'package:base/core/services/base/asset_service.dart';

extension IntExtensions on int {
  String get withQuestions =>
      this == 1 || this > 10 ? "$this سؤال" : "$this أسئلة";
  String get withMinutes =>
      this == 1 || this > 10 ? "$this دقيقة" : "$this دقائق";
  String get withDevicesCount {
    if (this <= 10) return '$this أجهزة';
    return '$this جهاز';
  }

  String get withQuantitiesCount {
    // if (this <= 10) return '$this كميات';
    return '$this كمية';
  }

  Widget get vrSpace => SizedBox(height: toDouble());
  Widget get hrSpace => SizedBox(width: toDouble());
  String get twoDigits => "${toString().length == 2 ? this : "0$this"}";
  String get formatMinutesToArabic {
    try {
      if (this < 60) {
        return '$this ${this == 1 ? "دقيقة" : "دقائق"}';
      } else {
        final hours = (this / 60).floor();
        return '$hours ${hours == 1 ? "ساعة" : "ساعات"}';
      }
    } catch (e) {
      return "$this دقيقة";
    }
  }

  T? toGetObject<T>(List<T> list, int Function(T item) idOf) {
    for (final item in list) {
      if (idOf(item) == this) return item;
    }
    return null;
  }

  String? get leaderboardRankSubtitle {
    if (this == 1) return 'المركز الاول في التحدي حتي الان';
    if (this == 2) return 'المركز الثاني في التحدي';
    if (this == 3) return 'المركز الثالث في التحدي';
    return null;
  }

  String? get leaderboardRankIcon {
    if (this == 1) return Assets.rank1;
    if (this == 2) return Assets.rank2;
    if (this == 3) return Assets.rank3;
    return null;
  }

  String? get leaderboardHeaderImage {
    if (this == 0) return Assets.leaderboard3;
    if (this == 1) return Assets.leaderboard2;
    if (this == 2) return Assets.leaderboard1;
    return null;
  }

  bool isCenterRank(int? remainingDays) =>
      remainingDays == null ? false : ((90 - remainingDays) ~/ 30) + 1 == this;

  String get leaderboardImage {
    final rank = ((90 - this) ~/ 30) + 1;
    if (rank == 1) return Assets.leaderboard1;
    if (rank == 2) return Assets.leaderboard2;
    return Assets.leaderboard3;
  }
}
