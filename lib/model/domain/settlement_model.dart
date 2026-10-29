import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class SettlementModel extends Equatable {
  const SettlementModel({
    required this.id,
    required this.providerName,
    required this.periodLabel,
    required this.grossMinor,
    required this.commissionMinor,
    required this.netMinor,
    required this.collectedMinor,
    this.requestedMinor = 0,
    required this.status,
    required this.createdAtMillis,
    required this.createdBy,
    required this.approvalStatus,
    this.approvedBy,
    this.brandId = '',
    this.brandName = '',
    this.receivingCompanyId = '',
    this.receivingCompanyName = '',
    this.destinationBankAccountId = '',
    this.destinationBankAccountName = '',
    this.posMachineId = '',
    this.posMachineName = '',
    this.includedTransactionIds = const [],
    this.evidenceStatus = 'unavailable',
    this.evidenceVerifiedBy,
    this.evidenceVerifiedAtMillis,
    this.actualCollectionDateMillis,
    this.settlementDateMillis,
    this.expectedCollectionDateMillis,
    this.rejectionReason = '',
    this.rejectedBy,
    this.rejectedAtMillis,
  });
  final String id;
  final String providerName;
  final String periodLabel;
  final int grossMinor;
  final int commissionMinor;
  final int netMinor;
  final int collectedMinor;
  final int requestedMinor;
  final String status;
  final int createdAtMillis;
  final String createdBy;
  final String approvalStatus;
  final String? approvedBy;
  final String brandId;
  final String brandName;
  final String receivingCompanyId;
  final String receivingCompanyName;
  final String destinationBankAccountId;
  final String destinationBankAccountName;
  final String posMachineId;
  final String posMachineName;
  final List<String> includedTransactionIds;
  final String evidenceStatus;
  final String? evidenceVerifiedBy;
  final int? evidenceVerifiedAtMillis;
  final int? actualCollectionDateMillis;
  final int? settlementDateMillis;
  final int? expectedCollectionDateMillis;
  final String rejectionReason;
  final String? rejectedBy;
  final int? rejectedAtMillis;

  factory SettlementModel.fromJson(Object? json) => SettlementModel(
    id: asStringOr(json, 'id'),
    providerName: asStringOr(json, 'providerName'),
    periodLabel: asStringOr(json, 'periodLabel'),
    grossMinor: asIntOr(json, 'grossMinor'),
    commissionMinor: asIntOr(json, 'commissionMinor'),
    netMinor: asIntOr(json, 'netMinor'),
    collectedMinor: asIntOr(json, 'collectedMinor'),
    requestedMinor: asIntOr(json, 'requestedMinor'),
    status: asStringOr(json, 'status', fallback: 'open'),
    createdAtMillis: asIntOr(json, 'createdAtMillis'),
    createdBy: asStringOr(json, 'createdBy'),
    approvalStatus: asStringOr(json, 'approvalStatus', fallback: 'approved'),
    approvedBy: asStringOrNull(json, 'approvedBy'),
    brandId: asStringOr(json, 'brandId'),
    brandName: asStringOr(json, 'brandName'),
    receivingCompanyId: asStringOr(json, 'receivingCompanyId'),
    receivingCompanyName: asStringOr(json, 'receivingCompanyName'),
    destinationBankAccountId: asStringOr(json, 'destinationBankAccountId'),
    destinationBankAccountName: asStringOr(json, 'destinationBankAccountName'),
    posMachineId: asStringOr(json, 'posMachineId'),
    posMachineName: asStringOr(json, 'posMachineName'),
    includedTransactionIds: json is Map
        ? ((json['includedTransactionIds'] as List?) ?? const [])
              .whereType<String>()
              .toList()
        : const [],
    evidenceStatus: asStringOr(json, 'evidenceStatus', fallback: 'unavailable'),
    evidenceVerifiedBy: asStringOrNull(json, 'evidenceVerifiedBy'),
    evidenceVerifiedAtMillis: asIntOrNull(json, 'evidenceVerifiedAtMillis'),
    actualCollectionDateMillis: asIntOrNull(json, 'actualCollectionDateMillis'),
    settlementDateMillis: asIntOrNull(json, 'settlementDateMillis'),
    expectedCollectionDateMillis: asIntOrNull(
      json,
      'expectedCollectionDateMillis',
    ),
    rejectionReason: asStringOr(json, 'rejectionReason'),
    rejectedBy: asStringOrNull(json, 'rejectedBy'),
    rejectedAtMillis: asIntOrNull(json, 'rejectedAtMillis'),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'providerName': providerName,
    'periodLabel': periodLabel,
    'grossMinor': grossMinor,
    'commissionMinor': commissionMinor,
    'netMinor': netMinor,
    'collectedMinor': collectedMinor,
    'requestedMinor': requestedMinor,
    'status': status,
    'createdAtMillis': createdAtMillis,
    'createdBy': createdBy,
    'approvalStatus': approvalStatus,
    'approvedBy': approvedBy,
    'brandId': brandId,
    'brandName': brandName,
    'receivingCompanyId': receivingCompanyId,
    'receivingCompanyName': receivingCompanyName,
    'destinationBankAccountId': destinationBankAccountId,
    'destinationBankAccountName': destinationBankAccountName,
    'posMachineId': posMachineId,
    'posMachineName': posMachineName,
    'includedTransactionIds': includedTransactionIds,
    'evidenceStatus': evidenceStatus,
    'evidenceVerifiedBy': evidenceVerifiedBy,
    'evidenceVerifiedAtMillis': evidenceVerifiedAtMillis,
    'actualCollectionDateMillis': actualCollectionDateMillis,
    'settlementDateMillis': settlementDateMillis,
    'expectedCollectionDateMillis': expectedCollectionDateMillis,
    'rejectionReason': rejectionReason,
    'rejectedBy': rejectedBy,
    'rejectedAtMillis': rejectedAtMillis,
  };
  @override
  List<Object?> get props => [
    id,
    collectedMinor,
    requestedMinor,
    status,
    approvalStatus,
    createdAtMillis,
  ];
}
