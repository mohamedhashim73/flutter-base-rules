import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class ExpenseModel extends Equatable {
  const ExpenseModel({
    required this.id,
    required this.category,
    required this.description,
    required this.amountMinor,
    required this.accountId,
    required this.status,
    required this.createdBy,
    required this.createdAtMillis,
    this.updatedAtMillis,
    this.beneficiary = '',
    this.notes = '',
    this.expenseDateMillis,
  });
  final String id;
  final String category;
  final String description;
  final int amountMinor;
  final String accountId;
  final String status;
  final String createdBy;
  final int createdAtMillis;
  final int? updatedAtMillis;
  final String beneficiary;
  final String notes;
  final int? expenseDateMillis;

  factory ExpenseModel.fromJson(Object? json) => ExpenseModel(
    id: asStringOr(json, 'id'),
    category: asStringOr(json, 'category'),
    description: asStringOr(json, 'description'),
    amountMinor: asIntOr(json, 'amountMinor'),
    accountId: asStringOr(json, 'accountId'),
    status: asStringOr(json, 'status', fallback: 'approved'),
    createdBy: asStringOr(json, 'createdBy'),
    createdAtMillis: asIntOr(json, 'createdAtMillis'),
    updatedAtMillis: asIntOrNull(json, 'updatedAtMillis'),
    beneficiary: asStringOr(json, 'beneficiary'),
    notes: asStringOr(json, 'notes'),
    expenseDateMillis: asIntOrNull(json, 'expenseDateMillis'),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'description': description,
    'amountMinor': amountMinor,
    'accountId': accountId,
    'status': status,
    'createdBy': createdBy,
    'createdAtMillis': createdAtMillis,
    'updatedAtMillis': updatedAtMillis ?? createdAtMillis,
    'beneficiary': beneficiary,
    'notes': notes,
    'expenseDateMillis': expenseDateMillis,
  };
  @override
  List<Object?> get props => [
    id,
    amountMinor,
    status,
    beneficiary,
    expenseDateMillis,
    updatedAtMillis,
    createdAtMillis,
  ];
}
