import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class CreditDepositModel extends Equatable {
  const CreditDepositModel({
    required this.id,
    required this.cardId,
    required this.amountMinor,
    required this.depositDateMillis,
    required this.qualifiesForMonthlyDebt,
    required this.createdBy,
    required this.createdAtMillis,
    this.approvalStatus = 'approved',
    this.approvedBy,
    this.approvedAtMillis,
  });

  final String id;
  final String cardId;
  final int amountMinor;
  final int depositDateMillis;
  final bool qualifiesForMonthlyDebt;
  final String createdBy;
  final int createdAtMillis;
  final String approvalStatus;
  final String? approvedBy;
  final int? approvedAtMillis;

  factory CreditDepositModel.fromJson(Object? json) => CreditDepositModel(
    id: asStringOr(json, 'id'),
    cardId: asStringOr(json, 'cardId'),
    amountMinor: asIntOr(json, 'amountMinor'),
    depositDateMillis: asIntOr(json, 'depositDateMillis'),
    qualifiesForMonthlyDebt: asBoolOr(
      json,
      'qualifiesForMonthlyDebt',
      fallback: true,
    ),
    createdBy: asStringOr(json, 'createdBy'),
    createdAtMillis: asIntOr(json, 'createdAtMillis'),
    approvalStatus: asStringOr(json, 'approvalStatus', fallback: 'approved'),
    approvedBy: asStringOrNull(json, 'approvedBy'),
    approvedAtMillis: asIntOrNull(json, 'approvedAtMillis'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'cardId': cardId,
    'amountMinor': amountMinor,
    'depositDateMillis': depositDateMillis,
    'qualifiesForMonthlyDebt': qualifiesForMonthlyDebt,
    'createdBy': createdBy,
    'createdAtMillis': createdAtMillis,
    'approvalStatus': approvalStatus,
    'approvedBy': approvedBy,
    'approvedAtMillis': approvedAtMillis,
  };

  @override
  List<Object?> get props => [id, createdAtMillis, approvalStatus];
}
