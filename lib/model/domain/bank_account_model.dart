import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class BankAccountModel extends Equatable {
  const BankAccountModel({
    required this.id,
    required this.bankName,
    required this.accountName,
    required this.lastFour,
    required this.active,
    required this.updatedAtMillis,
    this.openingBalanceMinor = 0,
    int? balanceMinor,
  }) : balanceMinor = balanceMinor ?? openingBalanceMinor;
  final String id;
  final String bankName;
  final String accountName;
  final String lastFour;
  final bool active;
  final int updatedAtMillis;
  final int openingBalanceMinor;
  final int balanceMinor;
  factory BankAccountModel.fromJson(Object? json) => BankAccountModel(
    id: asStringOr(json, 'id'),
    bankName: asStringOr(json, 'bankName'),
    accountName: asStringOr(json, 'accountName'),
    lastFour: asStringOr(json, 'lastFour'),
    active: asBoolOr(json, 'active', fallback: true),
    updatedAtMillis: asIntOr(json, 'updatedAtMillis'),
    openingBalanceMinor: asIntOr(json, 'openingBalanceMinor'),
    balanceMinor: asIntOr(
      json,
      'balanceMinor',
      fallback: asIntOr(json, 'openingBalanceMinor'),
    ),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'bankName': bankName,
    'accountName': accountName,
    'lastFour': lastFour,
    'active': active,
    'updatedAtMillis': updatedAtMillis,
    'openingBalanceMinor': openingBalanceMinor,
    'balanceMinor': balanceMinor,
  };

  BankAccountModel copyWith({
    String? bankName,
    String? accountName,
    String? lastFour,
    bool? active,
    int? updatedAtMillis,
  }) => BankAccountModel(
    id: id,
    bankName: bankName ?? this.bankName,
    accountName: accountName ?? this.accountName,
    lastFour: lastFour ?? this.lastFour,
    active: active ?? this.active,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    openingBalanceMinor: openingBalanceMinor,
    balanceMinor: balanceMinor,
  );
  @override
  List<Object?> get props => [
    id,
    bankName,
    accountName,
    lastFour,
    active,
    openingBalanceMinor,
    balanceMinor,
  ];
}
