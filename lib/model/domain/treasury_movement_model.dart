import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class TreasuryMovementModel extends Equatable {
  const TreasuryMovementModel({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amountMinor,
    required this.note,
    required this.createdBy,
    required this.createdAtMillis,
    required this.approvalStatus,
    this.relatedParty = '',
    this.transactionDateMillis,
    this.approvedBy,
    this.approvedAtMillis,
  });
  final String id;
  final String accountId;
  final String type;
  final int amountMinor;
  final String note;
  final String createdBy;
  final int createdAtMillis;
  final String approvalStatus;
  final String relatedParty;
  final int? transactionDateMillis;
  final String? approvedBy;
  final int? approvedAtMillis;

  factory TreasuryMovementModel.fromJson(Object? json) => TreasuryMovementModel(
    id: asStringOr(json, 'id'),
    accountId: asStringOr(json, 'accountId'),
    type: asStringOr(json, 'type'),
    amountMinor: asIntOr(json, 'amountMinor'),
    note: asStringOr(json, 'note'),
    createdBy: asStringOr(json, 'createdBy'),
    createdAtMillis: asIntOr(json, 'createdAtMillis'),
    approvalStatus: asStringOr(json, 'approvalStatus', fallback: 'approved'),
    relatedParty: asStringOr(json, 'relatedParty'),
    transactionDateMillis: asIntOrNull(json, 'transactionDateMillis'),
    approvedBy: asStringOrNull(json, 'approvedBy'),
    approvedAtMillis: asIntOrNull(json, 'approvedAtMillis'),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'type': type,
    'amountMinor': amountMinor,
    'note': note,
    'createdBy': createdBy,
    'createdAtMillis': createdAtMillis,
    'approvalStatus': approvalStatus,
    'relatedParty': relatedParty,
    'transactionDateMillis': transactionDateMillis,
    'approvedBy': approvedBy,
    'approvedAtMillis': approvedAtMillis,
  };
  @override
  List<Object?> get props => [
    id,
    accountId,
    amountMinor,
    approvalStatus,
    relatedParty,
    transactionDateMillis,
    createdAtMillis,
  ];
}
