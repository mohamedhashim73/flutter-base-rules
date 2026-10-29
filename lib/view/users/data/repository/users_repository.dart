import 'package:base/model/domain/managed_user_model.dart';

abstract interface class UsersRepository {
  Future<List<ManagedUserModel>> listUsers();
  Future<void> createUser({
    required String email,
    required String displayName,
    required String temporaryPassword,
    required String role,
    required Map<String, bool> permissions,
  });
  Future<void> updateAccess({
    required String uid,
    required String role,
    required Map<String, bool> permissions,
  });
}
