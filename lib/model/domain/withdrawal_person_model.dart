import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class WithdrawalPersonModel extends Equatable {
  const WithdrawalPersonModel({
    required this.id,
    required this.name,
    required this.active,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });

  final String id;
  final String name;
  final bool active;
  final int createdAtMillis;
  final int updatedAtMillis;

  factory WithdrawalPersonModel.fromJson(Object? json) => WithdrawalPersonModel(
    id: asStringOr(json, 'id'),
    name: asStringOr(json, 'name'),
    active: asBoolOr(json, 'active', fallback: true),
    createdAtMillis: asIntOr(json, 'createdAtMillis'),
    updatedAtMillis: asIntOr(json, 'updatedAtMillis'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'active': active,
    'createdAtMillis': createdAtMillis,
    'updatedAtMillis': updatedAtMillis,
  };

  WithdrawalPersonModel copyWith({
    String? name,
    bool? active,
    int? updatedAtMillis,
  }) => WithdrawalPersonModel(
    id: id,
    name: name ?? this.name,
    active: active ?? this.active,
    createdAtMillis: createdAtMillis,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    active,
    createdAtMillis,
    updatedAtMillis,
  ];
}
