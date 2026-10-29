import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class PosMachineModel extends Equatable {
  const PosMachineModel({
    required this.id,
    required this.name,
    required this.providerId,
    required this.providerName,
    required this.active,
    required this.updatedAtMillis,
  });

  final String id;
  final String name;
  final String providerId;
  final String providerName;
  final bool active;
  final int updatedAtMillis;

  factory PosMachineModel.fromJson(Object? json) => PosMachineModel(
    id: asStringOr(json, 'id'),
    name: asStringOr(json, 'name'),
    providerId: asStringOr(json, 'providerId'),
    providerName: asStringOr(json, 'providerName'),
    active: asBoolOr(json, 'active', fallback: true),
    updatedAtMillis: asIntOr(json, 'updatedAtMillis'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'providerId': providerId,
    'providerName': providerName,
    'active': active,
    'updatedAtMillis': updatedAtMillis,
  };

  PosMachineModel copyWith({
    String? name,
    bool? active,
    int? updatedAtMillis,
  }) => PosMachineModel(
    id: id,
    name: name ?? this.name,
    providerId: providerId,
    providerName: providerName,
    active: active ?? this.active,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
  );

  @override
  List<Object?> get props => [id, name, providerId, active, updatedAtMillis];
}
