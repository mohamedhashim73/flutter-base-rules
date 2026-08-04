import 'package:base/model/base/base_response.dart';
import 'package:playx/playx.dart';

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
  final String? refreshToken;

  const UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    this.compoundId,
    this.profilePicture,
    this.accessToken,
    this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {UserModel? profile}) {
    final user = asMapOr(json, 'user',fallback: json);
    return UserModel(
      id: asInt(user, "id"),
      name: asStringOr(user, "name"),
      email: asStringOr(user, "email"),
      phone: asStringOr(user, "phone"),
      compoundId: asIntOrNull(user, "compound_id"),
      profilePicture: asStringOr(user, "profile_picture"),
      accessToken: profile?.accessToken ?? asStringOr(json, "access_token"),
      refreshToken: profile?.refreshToken ?? asStringOr(json, "refresh_token"),
    );
  }

  Map<String, dynamic> get toJson => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'refresh_token': refreshToken,
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
    String? refreshToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      compoundId: compoundId ?? this.compoundId,
      profilePicture: profilePicture ?? this.profilePicture,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  @override
  List<Object?> get props => [id];
}
