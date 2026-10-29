import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class TreasuryAccountModel extends Equatable {
  const TreasuryAccountModel({
    required this.id,
    required this.name,
    required this.balanceMinor,
    required this.active,
    required this.updatedAtMillis,
    this.openingBalanceMinor = 0,
  });
  final String id;
  final String name;
  final int balanceMinor;
  final bool active;
  final int updatedAtMillis;
  final int openingBalanceMinor;

  factory TreasuryAccountModel.fromJson(Object? json) => TreasuryAccountModel(
    id: asStringOr(json, 'id'),
    name: asStringOr(json, 'name'),
    balanceMinor: asIntOr(json, 'balanceMinor'),
    active: asBoolOr(json, 'active', fallback: true),
    updatedAtMillis: asIntOr(json, 'updatedAtMillis'),
    openingBalanceMinor: asIntOr(json, 'openingBalanceMinor'),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'balanceMinor': balanceMinor,
    'active': active,
    'updatedAtMillis': updatedAtMillis,
    'openingBalanceMinor': openingBalanceMinor,
  };
  @override
  List<Object?> get props => [
    id,
    balanceMinor,
    openingBalanceMinor,
    updatedAtMillis,
  ];
}
