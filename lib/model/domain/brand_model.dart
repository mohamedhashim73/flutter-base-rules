import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class BrandModel extends Equatable {
  const BrandModel({
    required this.id,
    required this.name,
    required this.providerId,
    required this.providerName,
    required this.commissionBps,
    required this.active,
    required this.updatedAtMillis,
    this.receivingCompanyId = '',
    this.receivingCompanyName = '',
    this.settlementBankAccountId = '',
    this.settlementBankAccountName = '',
    this.posMachineId = '',
    this.posMachineName = '',
  });

  final String id;
  final String name;
  final String providerId;
  final String providerName;
  final int commissionBps;
  final bool active;
  final int updatedAtMillis;
  final String receivingCompanyId;
  final String receivingCompanyName;
  final String settlementBankAccountId;
  final String settlementBankAccountName;
  final String posMachineId;
  final String posMachineName;

  factory BrandModel.fromJson(Object? json) => BrandModel(
    id: asStringOr(json, 'id'),
    name: asStringOr(json, 'name'),
    providerId: asStringOr(json, 'providerId'),
    providerName: asStringOr(json, 'providerName'),
    commissionBps: asIntOr(json, 'commissionBps'),
    active: asBoolOr(json, 'active', fallback: true),
    updatedAtMillis: asIntOr(json, 'updatedAtMillis'),
    receivingCompanyId: asStringOr(json, 'receivingCompanyId'),
    receivingCompanyName: asStringOr(json, 'receivingCompanyName'),
    settlementBankAccountId: asStringOr(json, 'settlementBankAccountId'),
    settlementBankAccountName: asStringOr(json, 'settlementBankAccountName'),
    posMachineId: asStringOr(json, 'posMachineId'),
    posMachineName: asStringOr(json, 'posMachineName'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'providerId': providerId,
    'providerName': providerName,
    'commissionBps': commissionBps,
    'active': active,
    'updatedAtMillis': updatedAtMillis,
    'receivingCompanyId': receivingCompanyId,
    'receivingCompanyName': receivingCompanyName,
    'settlementBankAccountId': settlementBankAccountId,
    'settlementBankAccountName': settlementBankAccountName,
    'posMachineId': posMachineId,
    'posMachineName': posMachineName,
  };

  BrandModel copyWith({
    String? name,
    String? providerId,
    String? providerName,
    int? commissionBps,
    bool? active,
    int? updatedAtMillis,
    String? receivingCompanyId,
    String? receivingCompanyName,
    String? settlementBankAccountId,
    String? settlementBankAccountName,
    String? posMachineId,
    String? posMachineName,
  }) {
    return BrandModel(
      id: id,
      name: name ?? this.name,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      commissionBps: commissionBps ?? this.commissionBps,
      active: active ?? this.active,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      receivingCompanyId: receivingCompanyId ?? this.receivingCompanyId,
      receivingCompanyName: receivingCompanyName ?? this.receivingCompanyName,
      settlementBankAccountId:
          settlementBankAccountId ?? this.settlementBankAccountId,
      settlementBankAccountName:
          settlementBankAccountName ?? this.settlementBankAccountName,
      posMachineId: posMachineId ?? this.posMachineId,
      posMachineName: posMachineName ?? this.posMachineName,
    );
  }

  @override
  List<Object?> get props => [id, updatedAtMillis];
}
