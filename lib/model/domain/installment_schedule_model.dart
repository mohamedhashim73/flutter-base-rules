import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class InstallmentScheduleModel extends Equatable {
  const InstallmentScheduleModel({
    required this.id,
    required this.accountId,
    required this.description,
    required this.principalMinor,
    required this.totalDueMinor,
    required this.monthlyAmountMinor,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.nextDueMillis,
    required this.status,
    required this.createdAtMillis,
  });

  final String id;
  final String accountId;
  final String description;
  final int principalMinor;
  final int totalDueMinor;
  final int monthlyAmountMinor;
  final int totalInstallments;
  final int paidInstallments;
  final int nextDueMillis;
  final String status;
  final int createdAtMillis;

  int get remainingInstallments =>
      (totalInstallments - paidInstallments).clamp(0, totalInstallments);

  factory InstallmentScheduleModel.fromJson(Object? json) =>
      InstallmentScheduleModel(
        id: asStringOr(json, 'id'),
        accountId: asStringOr(json, 'accountId'),
        description: asStringOr(json, 'description'),
        principalMinor: asIntOr(json, 'principalMinor'),
        totalDueMinor: asIntOr(json, 'totalDueMinor'),
        monthlyAmountMinor: asIntOr(json, 'monthlyAmountMinor'),
        totalInstallments: asIntOr(json, 'totalInstallments'),
        paidInstallments: asIntOr(json, 'paidInstallments'),
        nextDueMillis: asIntOr(json, 'nextDueMillis'),
        status: asStringOr(json, 'status', fallback: 'active'),
        createdAtMillis: asIntOr(json, 'createdAtMillis'),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'description': description,
    'principalMinor': principalMinor,
    'totalDueMinor': totalDueMinor,
    'monthlyAmountMinor': monthlyAmountMinor,
    'totalInstallments': totalInstallments,
    'paidInstallments': paidInstallments,
    'nextDueMillis': nextDueMillis,
    'status': status,
    'createdAtMillis': createdAtMillis,
  };

  @override
  List<Object?> get props => [id, paidInstallments, nextDueMillis, status];
}
