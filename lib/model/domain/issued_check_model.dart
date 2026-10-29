import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class IssuedCheckModel extends Equatable {
  const IssuedCheckModel({
    required this.id,
    required this.payee,
    required this.reference,
    required this.amountMinor,
    required this.dueDateMillis,
    required this.status,
    required this.accountId,
    required this.createdAtMillis,
    this.notes = '',
    this.bankName = '',
    this.deductionDateMillis,
  });
  final String id;
  final String payee;
  final String reference;
  final int amountMinor;
  final int dueDateMillis;
  final String status;
  final String accountId;
  final int createdAtMillis;
  final String notes;
  final String bankName;
  final int? deductionDateMillis;

  factory IssuedCheckModel.fromJson(Object? json) => IssuedCheckModel(
    id: asStringOr(json, 'id'),
    payee: asStringOr(json, 'payee'),
    reference: asStringOr(json, 'reference'),
    amountMinor: asIntOr(json, 'amountMinor'),
    dueDateMillis: asIntOr(json, 'dueDateMillis'),
    status: asStringOr(json, 'status', fallback: 'issued'),
    accountId: asStringOr(json, 'accountId'),
    createdAtMillis: asIntOr(json, 'createdAtMillis'),
    notes: asStringOr(json, 'notes'),
    bankName: asStringOr(json, 'bankName'),
    deductionDateMillis: asIntOrNull(json, 'deductionDateMillis'),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'payee': payee,
    'reference': reference,
    'amountMinor': amountMinor,
    'dueDateMillis': dueDateMillis,
    'status': status,
    'accountId': accountId,
    'createdAtMillis': createdAtMillis,
    'notes': notes,
    'bankName': bankName,
    'deductionDateMillis': deductionDateMillis,
  };
  @override
  List<Object?> get props => [id, status, amountMinor, createdAtMillis];
}
