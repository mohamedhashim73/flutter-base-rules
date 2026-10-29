import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class TreasuryTransferModel extends Equatable {
  const TreasuryTransferModel({
    required this.id,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amountMinor,
    required this.feeMinor,
    required this.status,
    required this.createdBy,
    required this.createdAtMillis,
    this.sourceAccountType = 'treasury',
    this.destinationAccountType = 'treasury',
    this.approvedBy,
    this.approvedAtMillis,
  });
  final String id;
  final String sourceAccountId;
  final String destinationAccountId;
  final int amountMinor;
  final int feeMinor;
  final String status;
  final String createdBy;
  final int createdAtMillis;
  final String sourceAccountType;
  final String destinationAccountType;
  final String? approvedBy;
  final int? approvedAtMillis;
  factory TreasuryTransferModel.fromJson(Object? json) => TreasuryTransferModel(
    id: asStringOr(json, 'id'),
    sourceAccountId: asStringOr(json, 'sourceAccountId'),
    destinationAccountId: asStringOr(json, 'destinationAccountId'),
    amountMinor: asIntOr(json, 'amountMinor'),
    feeMinor: asIntOr(json, 'feeMinor'),
    status: asStringOr(json, 'status', fallback: 'approved'),
    createdBy: asStringOr(json, 'createdBy'),
    createdAtMillis: asIntOr(json, 'createdAtMillis'),
    sourceAccountType: asStringOr(
      json,
      'sourceAccountType',
      fallback: 'treasury',
    ),
    destinationAccountType: asStringOr(
      json,
      'destinationAccountType',
      fallback: 'treasury',
    ),
    approvedBy: asStringOrNull(json, 'approvedBy'),
    approvedAtMillis: asIntOrNull(json, 'approvedAtMillis'),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceAccountId': sourceAccountId,
    'destinationAccountId': destinationAccountId,
    'amountMinor': amountMinor,
    'feeMinor': feeMinor,
    'status': status,
    'createdBy': createdBy,
    'createdAtMillis': createdAtMillis,
    'sourceAccountType': sourceAccountType,
    'destinationAccountType': destinationAccountType,
    'approvedBy': approvedBy,
    'approvedAtMillis': approvedAtMillis,
  };
  @override
  List<Object?> get props => [
    id,
    sourceAccountId,
    destinationAccountId,
    amountMinor,
    status,
    sourceAccountType,
    destinationAccountType,
    approvedBy,
    approvedAtMillis,
  ];
}
