import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class CreditPeriodModel extends Equatable {
  const CreditPeriodModel({
    required this.id,
    required this.cardId,
    required this.year,
    required this.month,
    required this.openingBalanceMinor,
    required this.openingDebtMinor,
    required this.qualifyingDepositsMinor,
    required this.remainingDebtMinor,
    required this.closingBalanceMinor,
    required this.fullyPaid,
    required this.updatedAtMillis,
  });

  final String id;
  final String cardId;
  final int year;
  final int month;
  final int openingBalanceMinor;
  final int openingDebtMinor;
  final int qualifyingDepositsMinor;
  final int remainingDebtMinor;
  final int closingBalanceMinor;
  final bool fullyPaid;
  final int updatedAtMillis;

  factory CreditPeriodModel.fromJson(Object? json) => CreditPeriodModel(
    id: asStringOr(json, 'id'),
    cardId: asStringOr(json, 'cardId'),
    year: asIntOr(json, 'year'),
    month: asIntOr(json, 'month'),
    openingBalanceMinor: asIntOr(json, 'openingBalanceMinor'),
    openingDebtMinor: asIntOr(json, 'openingDebtMinor'),
    qualifyingDepositsMinor: asIntOr(json, 'qualifyingDepositsMinor'),
    remainingDebtMinor: asIntOr(json, 'remainingDebtMinor'),
    closingBalanceMinor: asIntOr(json, 'closingBalanceMinor'),
    fullyPaid: asBoolOr(json, 'fullyPaid'),
    updatedAtMillis: asIntOr(json, 'updatedAtMillis'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'cardId': cardId,
    'year': year,
    'month': month,
    'openingBalanceMinor': openingBalanceMinor,
    'openingDebtMinor': openingDebtMinor,
    'qualifyingDepositsMinor': qualifyingDepositsMinor,
    'remainingDebtMinor': remainingDebtMinor,
    'closingBalanceMinor': closingBalanceMinor,
    'fullyPaid': fullyPaid,
    'updatedAtMillis': updatedAtMillis,
  };

  CreditPeriodModel copyWith({
    int? qualifyingDepositsMinor,
    int? remainingDebtMinor,
    int? closingBalanceMinor,
    bool? fullyPaid,
    int? updatedAtMillis,
  }) => CreditPeriodModel(
    id: id,
    cardId: cardId,
    year: year,
    month: month,
    openingBalanceMinor: openingBalanceMinor,
    openingDebtMinor: openingDebtMinor,
    qualifyingDepositsMinor:
        qualifyingDepositsMinor ?? this.qualifyingDepositsMinor,
    remainingDebtMinor: remainingDebtMinor ?? this.remainingDebtMinor,
    closingBalanceMinor: closingBalanceMinor ?? this.closingBalanceMinor,
    fullyPaid: fullyPaid ?? this.fullyPaid,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
  );

  @override
  List<Object?> get props => [id, updatedAtMillis];
}
