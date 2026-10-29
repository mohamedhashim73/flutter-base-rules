import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class BankMovementModel extends Equatable {
  const BankMovementModel({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amountMinor,
    required this.referenceType,
    required this.referenceId,
    required this.note,
    required this.createdBy,
    required this.createdAtMillis,
    this.relatedParty = '',
    this.approvalStatus = 'approved',
    this.approvedBy,
    this.approvedAtMillis,
    this.updatedAtMillis,
  });

  final String id;
  final String accountId;
  final String type;
  final int amountMinor;
  final String referenceType;
  final String referenceId;
  final String note;
  final String createdBy;
  final int createdAtMillis;
  final String relatedParty;
  final String approvalStatus;
  final String? approvedBy;
  final int? approvedAtMillis;
  final int? updatedAtMillis;

  factory BankMovementModel.fromJson(Object? json) => BankMovementModel(
    id: asStringOr(json, 'id'),
    accountId: asStringOr(json, 'accountId'),
    type: asStringOr(json, 'type'),
    amountMinor: asIntOr(json, 'amountMinor'),
    referenceType: asStringOr(json, 'referenceType'),
    referenceId: asStringOr(json, 'referenceId'),
    note: asStringOr(json, 'note'),
    createdBy: asStringOr(json, 'createdBy'),
    createdAtMillis: asIntOr(json, 'createdAtMillis'),
    relatedParty: asStringOr(json, 'relatedParty'),
    approvalStatus: asStringOr(json, 'approvalStatus', fallback: 'approved'),
    approvedBy: asStringOrNull(json, 'approvedBy'),
    approvedAtMillis: asIntOrNull(json, 'approvedAtMillis'),
    updatedAtMillis: asIntOrNull(json, 'updatedAtMillis'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'type': type,
    'amountMinor': amountMinor,
    'referenceType': referenceType,
    'referenceId': referenceId,
    'note': note,
    'createdBy': createdBy,
    'createdAtMillis': createdAtMillis,
    'relatedParty': relatedParty,
    'approvalStatus': approvalStatus,
    'approvedBy': approvedBy,
    'approvedAtMillis': approvedAtMillis,
    'updatedAtMillis': updatedAtMillis,
  };

  @override
  List<Object?> get props => [
    id,
    accountId,
    type,
    amountMinor,
    approvalStatus,
    createdAtMillis,
  ];
}
