import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class TreasuryReconciliationModel extends Equatable {
  const TreasuryReconciliationModel({
    required this.id,
    required this.accountId,
    required this.expectedMinor,
    required this.actualMinor,
    required this.differenceMinor,
    required this.reason,
    required this.createdBy,
    required this.createdAtMillis,
    this.beforeBalanceMinor = 0,
    this.afterBalanceMinor = 0,
    this.adjustmentMovementId = '',
  });
  final String id;
  final String accountId;
  final int expectedMinor;
  final int actualMinor;
  final int differenceMinor;
  final String reason;
  final String createdBy;
  final int createdAtMillis;
  final int beforeBalanceMinor;
  final int afterBalanceMinor;
  final String adjustmentMovementId;
  factory TreasuryReconciliationModel.fromJson(Object? json) =>
      TreasuryReconciliationModel(
        id: asStringOr(json, 'id'),
        accountId: asStringOr(json, 'accountId'),
        expectedMinor: asIntOr(json, 'expectedMinor'),
        actualMinor: asIntOr(json, 'actualMinor'),
        differenceMinor: asIntOr(json, 'differenceMinor'),
        reason: asStringOr(json, 'reason'),
        createdBy: asStringOr(json, 'createdBy'),
        createdAtMillis: asIntOr(json, 'createdAtMillis'),
        beforeBalanceMinor: asIntOr(json, 'beforeBalanceMinor'),
        afterBalanceMinor: asIntOr(json, 'afterBalanceMinor'),
        adjustmentMovementId: asStringOr(json, 'adjustmentMovementId'),
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'expectedMinor': expectedMinor,
    'actualMinor': actualMinor,
    'differenceMinor': differenceMinor,
    'reason': reason,
    'createdBy': createdBy,
    'createdAtMillis': createdAtMillis,
    'beforeBalanceMinor': beforeBalanceMinor,
    'afterBalanceMinor': afterBalanceMinor,
    'adjustmentMovementId': adjustmentMovementId,
  };
  @override
  List<Object?> get props => [
    id,
    accountId,
    differenceMinor,
    beforeBalanceMinor,
    afterBalanceMinor,
    createdAtMillis,
  ];
}
