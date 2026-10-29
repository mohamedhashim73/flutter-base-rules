import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class PersonalWithdrawalModel extends Equatable {
  const PersonalWithdrawalModel({
    required this.id,
    required this.personName,
    required this.accountId,
    required this.amountMinor,
    required this.reason,
    required this.createdBy,
    required this.createdAtMillis,
    required this.status,
    this.approvedBy,
    this.approvedAtMillis,
    this.withdrawalDateMillis,
    this.updatedAtMillis,
  });
  final String id;
  final String personName;
  final String accountId;
  final int amountMinor;
  final String reason;
  final String createdBy;
  final int createdAtMillis;
  final String status;
  final String? approvedBy;
  final int? approvedAtMillis;
  final int? withdrawalDateMillis;
  final int? updatedAtMillis;
  factory PersonalWithdrawalModel.fromJson(Object? json) =>
      PersonalWithdrawalModel(
        id: asStringOr(json, 'id'),
        personName: asStringOr(json, 'personName'),
        accountId: asStringOr(json, 'accountId'),
        amountMinor: asIntOr(json, 'amountMinor'),
        reason: asStringOr(json, 'reason'),
        createdBy: asStringOr(json, 'createdBy'),
        createdAtMillis: asIntOr(json, 'createdAtMillis'),
        status: asStringOr(json, 'status', fallback: 'approved'),
        approvedBy: asStringOrNull(json, 'approvedBy'),
        approvedAtMillis: asIntOrNull(json, 'approvedAtMillis'),
        withdrawalDateMillis: asIntOrNull(json, 'withdrawalDateMillis'),
        updatedAtMillis:
            asIntOrNull(json, 'updatedAtMillis') ??
            asIntOr(json, 'createdAtMillis'),
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'personName': personName,
    'accountId': accountId,
    'amountMinor': amountMinor,
    'reason': reason,
    'createdBy': createdBy,
    'createdAtMillis': createdAtMillis,
    'status': status,
    'approvedBy': approvedBy,
    'approvedAtMillis': approvedAtMillis,
    'withdrawalDateMillis': withdrawalDateMillis,
    'updatedAtMillis': updatedAtMillis ?? createdAtMillis,
  };
  @override
  List<Object?> get props => [
    id,
    personName,
    accountId,
    amountMinor,
    status,
    approvedBy,
    approvedAtMillis,
    withdrawalDateMillis,
    updatedAtMillis,
    createdAtMillis,
  ];
}
