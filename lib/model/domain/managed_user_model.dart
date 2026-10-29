import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class ManagedUserModel extends Equatable {
  const ManagedUserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.permissions,
    required this.active,
    required this.createdAtMillis,
  });
  final String id;
  final String email;
  final String displayName;
  final String role;
  final Map<String, bool> permissions;
  final bool active;
  final int createdAtMillis;

  factory ManagedUserModel.fromJson(Object? json) {
    final map = json is Map
        ? Map<String, dynamic>.from(json)
        : <String, dynamic>{};
    final rawPermissions = map['permissions'];
    return ManagedUserModel(
      id: asStringOr(map, 'id'),
      email: asStringOr(map, 'email'),
      displayName: asStringOr(map, 'displayName'),
      role: asStringOr(map, 'role', fallback: 'employee'),
      permissions: rawPermissions is Map
          ? rawPermissions.map(
              (key, value) => MapEntry(key.toString(), value == true),
            )
          : const {},
      active: asBoolOr(map, 'active', fallback: true),
      createdAtMillis: asIntOr(map, 'createdAtMillis'),
    );
  }

  @override
  List<Object?> get props => [id, role, permissions, active];
}
