import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class InstallmentAccountModel extends Equatable {
  const InstallmentAccountModel({
    required this.id,
    required this.customerName,
    required this.reference,
    required this.principalMinor,
    required this.totalDueMinor,
    required this.paidMinor,
    required this.nextDueMillis,
    required this.status,
    required this.createdAtMillis,
    this.monthlyInstallmentMinor = 0,
    this.totalInstallments = 0,
    this.paidInstallments = 0,
    this.applicationName = '',
    this.associatedPerson = '',
    this.totalLimitMinor = 0,
    this.availableMinor = 0,
  });
  final String id;
  final String customerName;
  final String reference;
  final int principalMinor;
  final int totalDueMinor;
  final int paidMinor;
  final int nextDueMillis;
  final String status;
  final int createdAtMillis;
  final int monthlyInstallmentMinor;
  final int totalInstallments;
  final int paidInstallments;
  final String applicationName;
  final String associatedPerson;
  final int totalLimitMinor;
  final int availableMinor;
  int get remainingMinor => totalDueMinor - paidMinor;
  int get monthlyObligationMinor =>
      monthlyInstallmentMinor > 0 ? monthlyInstallmentMinor : remainingMinor;
  int get currentAvailableMinor => totalLimitMinor > 0
      ? (availableMinor != 0
            ? availableMinor
            : totalLimitMinor - principalMinor)
      : 0;

  factory InstallmentAccountModel.fromJson(Object? json) =>
      InstallmentAccountModel(
        id: asStringOr(json, 'id'),
        customerName: asStringOr(json, 'customerName'),
        reference: asStringOr(json, 'reference'),
        principalMinor: asIntOr(json, 'principalMinor'),
        totalDueMinor: asIntOr(json, 'totalDueMinor'),
        paidMinor: asIntOr(json, 'paidMinor'),
        nextDueMillis: asIntOr(json, 'nextDueMillis'),
        status: asStringOr(json, 'status', fallback: 'active'),
        createdAtMillis: asIntOr(json, 'createdAtMillis'),
        monthlyInstallmentMinor: asIntOr(json, 'monthlyInstallmentMinor'),
        totalInstallments: asIntOr(json, 'totalInstallments'),
        paidInstallments: asIntOr(json, 'paidInstallments'),
        applicationName: asStringOr(json, 'applicationName'),
        associatedPerson: asStringOr(json, 'associatedPerson'),
        totalLimitMinor: asIntOr(json, 'totalLimitMinor'),
        availableMinor: asIntOr(json, 'availableMinor'),
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'reference': reference,
    'principalMinor': principalMinor,
    'totalDueMinor': totalDueMinor,
    'paidMinor': paidMinor,
    'nextDueMillis': nextDueMillis,
    'status': status,
    'createdAtMillis': createdAtMillis,
    'monthlyInstallmentMinor': monthlyInstallmentMinor,
    'totalInstallments': totalInstallments,
    'paidInstallments': paidInstallments,
    'applicationName': applicationName,
    'associatedPerson': associatedPerson,
    'totalLimitMinor': totalLimitMinor,
    'availableMinor': availableMinor,
  };
  @override
  List<Object?> get props => [id, paidMinor, status, createdAtMillis];
}
