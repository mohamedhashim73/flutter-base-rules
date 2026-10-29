import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class ReceivingCompanyModel extends Equatable {
  ReceivingCompanyModel({
    required this.id,
    required this.name,
    required this.bankAccountId,
    required this.active,
    required this.updatedAtMillis,
    List<String>? bankAccountIds,
  }) : bankAccountIds = bankAccountIds == null || bankAccountIds.isEmpty
           ? (bankAccountId.isEmpty ? const [] : [bankAccountId])
           : List.unmodifiable(bankAccountIds);
  final String id;
  final String name;
  final String bankAccountId;
  final bool active;
  final int updatedAtMillis;
  final List<String> bankAccountIds;
  factory ReceivingCompanyModel.fromJson(Object? json) => ReceivingCompanyModel(
    id: asStringOr(json, 'id'),
    name: asStringOr(json, 'name'),
    bankAccountId: asStringOr(json, 'bankAccountId'),
    active: asBoolOr(json, 'active', fallback: true),
    updatedAtMillis: asIntOr(json, 'updatedAtMillis'),
    bankAccountIds: ((json is Map ? json['bankAccountIds'] : null) as List?)
        ?.whereType<String>()
        .toList(),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bankAccountId': bankAccountId,
    'active': active,
    'updatedAtMillis': updatedAtMillis,
    'bankAccountIds': bankAccountIds,
  };

  ReceivingCompanyModel copyWith({
    String? name,
    String? bankAccountId,
    bool? active,
    int? updatedAtMillis,
    List<String>? bankAccountIds,
  }) => ReceivingCompanyModel(
    id: id,
    name: name ?? this.name,
    bankAccountId: bankAccountId ?? this.bankAccountId,
    active: active ?? this.active,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    bankAccountIds: bankAccountIds ?? this.bankAccountIds,
  );
  @override
  List<Object?> get props => [id, name, bankAccountId, active, bankAccountIds];
}
