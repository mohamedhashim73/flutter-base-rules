import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class CreditCardModel extends Equatable {
  const CreditCardModel({
    required this.id,
    required this.title,
    required this.cardholderName,
    required this.bankName,
    required this.maskedNumber,
    required this.lastFour,
    required this.creditLimitMinor,
    required this.availableBalanceMinor,
    required this.monthlyPaidMinor,
    required this.currentMonthlyDebtMinor,
    required this.dueDay,
    required this.active,
    required this.notes,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    this.colorHex = '',
    this.logoUrl = '',
    this.statementClosingDay = 1,
    this.nextCreditLimitMinor,
  });

  final String id;
  final String title;
  final String cardholderName;
  final String bankName;
  final String maskedNumber;
  final String lastFour;
  final int creditLimitMinor;
  final int availableBalanceMinor;
  final int monthlyPaidMinor;
  final int currentMonthlyDebtMinor;
  final int dueDay;
  final bool active;
  final String notes;
  final int createdAtMillis;
  final int updatedAtMillis;
  final String colorHex;
  final String logoUrl;
  final int statementClosingDay;
  final int? nextCreditLimitMinor;

  factory CreditCardModel.fromJson(Object? json) {
    return CreditCardModel(
      id: asStringOr(json, 'id'),
      title: asStringOr(json, 'title'),
      cardholderName: asStringOr(json, 'cardholderName'),
      bankName: asStringOr(json, 'bankName'),
      maskedNumber: asStringOr(json, 'maskedNumber'),
      lastFour: asStringOr(json, 'lastFour'),
      creditLimitMinor: asIntOr(json, 'creditLimitMinor'),
      availableBalanceMinor: asIntOr(json, 'availableBalanceMinor'),
      monthlyPaidMinor: asIntOr(json, 'monthlyPaidMinor'),
      currentMonthlyDebtMinor: asIntOr(json, 'currentMonthlyDebtMinor'),
      dueDay: asIntOr(json, 'dueDay', fallback: 1),
      active: asBoolOr(json, 'active', fallback: true),
      notes: asStringOr(json, 'notes'),
      createdAtMillis: asIntOr(json, 'createdAtMillis'),
      updatedAtMillis: asIntOr(json, 'updatedAtMillis'),
      colorHex: asStringOr(json, 'colorHex'),
      logoUrl: asStringOr(json, 'logoUrl'),
      statementClosingDay: asIntOr(json, 'statementClosingDay', fallback: 1),
      nextCreditLimitMinor: asIntOrNull(json, 'nextCreditLimitMinor'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'cardholderName': cardholderName,
    'bankName': bankName,
    'maskedNumber': maskedNumber,
    'lastFour': lastFour,
    'creditLimitMinor': creditLimitMinor,
    'availableBalanceMinor': availableBalanceMinor,
    'monthlyPaidMinor': monthlyPaidMinor,
    'currentMonthlyDebtMinor': currentMonthlyDebtMinor,
    'dueDay': dueDay,
    'active': active,
    'notes': notes,
    'createdAtMillis': createdAtMillis,
    'updatedAtMillis': updatedAtMillis,
    'colorHex': colorHex,
    'logoUrl': logoUrl,
    'statementClosingDay': statementClosingDay,
    'nextCreditLimitMinor': nextCreditLimitMinor,
  };

  CreditCardModel copyWith({
    String? title,
    String? cardholderName,
    String? bankName,
    String? maskedNumber,
    String? lastFour,
    int? creditLimitMinor,
    int? availableBalanceMinor,
    int? monthlyPaidMinor,
    int? currentMonthlyDebtMinor,
    int? dueDay,
    bool? active,
    String? notes,
    int? updatedAtMillis,
    String? colorHex,
    String? logoUrl,
    int? statementClosingDay,
    int? nextCreditLimitMinor,
  }) {
    return CreditCardModel(
      id: id,
      title: title ?? this.title,
      cardholderName: cardholderName ?? this.cardholderName,
      bankName: bankName ?? this.bankName,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      lastFour: lastFour ?? this.lastFour,
      creditLimitMinor: creditLimitMinor ?? this.creditLimitMinor,
      availableBalanceMinor:
          availableBalanceMinor ?? this.availableBalanceMinor,
      monthlyPaidMinor: monthlyPaidMinor ?? this.monthlyPaidMinor,
      currentMonthlyDebtMinor:
          currentMonthlyDebtMinor ?? this.currentMonthlyDebtMinor,
      dueDay: dueDay ?? this.dueDay,
      active: active ?? this.active,
      notes: notes ?? this.notes,
      createdAtMillis: createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      colorHex: colorHex ?? this.colorHex,
      logoUrl: logoUrl ?? this.logoUrl,
      statementClosingDay: statementClosingDay ?? this.statementClosingDay,
      nextCreditLimitMinor: nextCreditLimitMinor ?? this.nextCreditLimitMinor,
    );
  }

  @override
  List<Object?> get props => [id, updatedAtMillis];
}
