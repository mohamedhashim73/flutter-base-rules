import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class PaymentProviderModel extends Equatable {
  const PaymentProviderModel({
    required this.id,
    required this.name,
    required this.active,
    required this.updatedAtMillis,
  });

  final String id;
  final String name;
  final bool active;
  final int updatedAtMillis;

  factory PaymentProviderModel.fromJson(Object? json) => PaymentProviderModel(
    id: asStringOr(json, 'id'),
    name: asStringOr(json, 'name'),
    active: asBoolOr(json, 'active', fallback: true),
    updatedAtMillis: asIntOr(json, 'updatedAtMillis'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'active': active,
    'updatedAtMillis': updatedAtMillis,
  };

  PaymentProviderModel copyWith({
    String? name,
    bool? active,
    int? updatedAtMillis,
  }) {
    return PaymentProviderModel(
      id: id,
      name: name ?? this.name,
      active: active ?? this.active,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  @override
  List<Object?> get props => [id, updatedAtMillis];
}
