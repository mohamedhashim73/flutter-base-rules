import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class CreditPurchaseModel extends Equatable {
  const CreditPurchaseModel({
    required this.id,
    required this.cardId,
    required this.brandId,
    required this.brandName,
    required this.providerId,
    required this.providerName,
    required this.amountMinor,
    required this.commissionMinor,
    required this.commissionBps,
    required this.expectedNetMinor,
    required this.purchaseDateMillis,
    required this.createdBy,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    required this.isDeleted,
    this.posMachineId = '',
    this.posMachineName = '',
  });

  final String id;
  final String cardId;
  final String brandId;
  final String brandName;
  final String providerId;
  final String providerName;
  final int amountMinor;
  final int commissionMinor;
  final int commissionBps;
  final int expectedNetMinor;
  final int purchaseDateMillis;
  final String createdBy;
  final int createdAtMillis;
  final int updatedAtMillis;
  final bool isDeleted;
  final String posMachineId;
  final String posMachineName;

  factory CreditPurchaseModel.fromJson(Object? json) => CreditPurchaseModel(
    id: asStringOr(json, 'id'),
    cardId: asStringOr(json, 'cardId'),
    brandId: asStringOr(json, 'brandId'),
    brandName: asStringOr(json, 'brandName'),
    providerId: asStringOr(json, 'providerId'),
    providerName: asStringOr(json, 'providerName'),
    amountMinor: asIntOr(json, 'amountMinor'),
    commissionMinor: asIntOr(json, 'commissionMinor'),
    commissionBps: asIntOr(json, 'commissionBps'),
    expectedNetMinor: asIntOr(json, 'expectedNetMinor'),
    purchaseDateMillis: asIntOr(json, 'purchaseDateMillis'),
    createdBy: asStringOr(json, 'createdBy'),
    createdAtMillis: asIntOr(json, 'createdAtMillis'),
    updatedAtMillis: asIntOr(json, 'updatedAtMillis'),
    isDeleted: asBoolOr(json, 'isDeleted'),
    posMachineId: asStringOr(json, 'posMachineId'),
    posMachineName: asStringOr(json, 'posMachineName'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'cardId': cardId,
    'brandId': brandId,
    'brandName': brandName,
    'providerId': providerId,
    'providerName': providerName,
    'amountMinor': amountMinor,
    'commissionMinor': commissionMinor,
    'commissionBps': commissionBps,
    'expectedNetMinor': expectedNetMinor,
    'purchaseDateMillis': purchaseDateMillis,
    'createdBy': createdBy,
    'createdAtMillis': createdAtMillis,
    'updatedAtMillis': updatedAtMillis,
    'isDeleted': isDeleted,
    'posMachineId': posMachineId,
    'posMachineName': posMachineName,
  };

  CreditPurchaseModel copyWith({
    int? amountMinor,
    int? commissionMinor,
    int? expectedNetMinor,
    int? updatedAtMillis,
    bool? isDeleted,
  }) => CreditPurchaseModel(
    id: id,
    cardId: cardId,
    brandId: brandId,
    brandName: brandName,
    providerId: providerId,
    providerName: providerName,
    amountMinor: amountMinor ?? this.amountMinor,
    commissionMinor: commissionMinor ?? this.commissionMinor,
    commissionBps: commissionBps,
    expectedNetMinor: expectedNetMinor ?? this.expectedNetMinor,
    purchaseDateMillis: purchaseDateMillis,
    createdBy: createdBy,
    createdAtMillis: createdAtMillis,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    isDeleted: isDeleted ?? this.isDeleted,
    posMachineId: posMachineId,
    posMachineName: posMachineName,
  );

  @override
  List<Object?> get props => [id, updatedAtMillis, isDeleted];
}
