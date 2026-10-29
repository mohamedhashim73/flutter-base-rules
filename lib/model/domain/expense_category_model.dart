import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class ExpenseCategoryModel extends Equatable {
  const ExpenseCategoryModel({
    required this.id,
    required this.name,
    required this.active,
    required this.createdAtMillis,
  });
  final String id;
  final String name;
  final bool active;
  final int createdAtMillis;
  factory ExpenseCategoryModel.fromJson(Object? json) => ExpenseCategoryModel(
    id: asStringOr(json, 'id'),
    name: asStringOr(json, 'name'),
    active: asBoolOr(json, 'active', fallback: true),
    createdAtMillis: asIntOr(json, 'createdAtMillis'),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'active': active,
    'createdAtMillis': createdAtMillis,
  };

  ExpenseCategoryModel copyWith({
    String? name,
    bool? active,
    int? createdAtMillis,
  }) => ExpenseCategoryModel(
    id: id,
    name: name ?? this.name,
    active: active ?? this.active,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
  );
  @override
  List<Object?> get props => [id, name, active];
}
