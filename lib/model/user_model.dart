import 'package:playx/playx.dart';
import 'package:base/model/base/base_response.dart';

class UserModel extends Equatable implements LoadableResponse<UserModel> {
  @override
  UserModel? get data => this;
  final int id;
  final String name;
  final String? email;
  final String phone;
  final int? compoundId;
  final String? profilePicture;
  final String? accessToken;

  const UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    this.compoundId,
    this.profilePicture,
    this.accessToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {UserModel? profile}) {
    final user = asMapOrNull(json, 'user');
    final userMap = user ?? json;
    return UserModel(
      id: asInt(userMap, "id"),
      name: asStringOr(userMap, "name"),
      email: asStringOr(userMap, "email"),
      phone: asStringOr(userMap, "phone"),
      compoundId: asIntOrNull(userMap, "compound_id"),
      profilePicture: asStringOr(userMap, "profile_picture"),
      accessToken: profile?.accessToken ?? asStringOr(json, "access_token"),
    );
  }

  Map<String, dynamic> get toJson => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'compound_id': compoundId,
    'profile_picture': profilePicture,
    'access_token': accessToken,
  };

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    int? compoundId,
    String? profilePicture,
    String? accessToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      compoundId: compoundId ?? this.compoundId,
      profilePicture: profilePicture ?? this.profilePicture,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  @override
  List<Object?> get props => [id];
}
