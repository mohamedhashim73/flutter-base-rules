part of '../enums.dart';

enum CreditMovementType { purchase, deposit, adjustment }

extension CreditMovementTypeX on String {
  CreditMovementType get toCreditMovementType {
    return CreditMovementType.values.firstWhere(
      (value) => value.name == this,
      orElse: () => CreditMovementType.adjustment,
    );
  }
}
