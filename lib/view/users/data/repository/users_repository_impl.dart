import 'package:base/core/constants/domain/firebase_collections.dart';
import 'package:base/core/services/services.dart';
import 'package:base/model/domain/managed_user_model.dart';
import 'users_repository.dart';

class UsersRepositoryImpl implements UsersRepository {
  UsersRepositoryImpl(this._firebaseService, this._authService);

  final FirebaseService _firebaseService;
  final FirebaseAuthService _authService;

  String _key(String email) => email.trim().toLowerCase();

  @override
  Future<List<ManagedUserModel>> listUsers() async =>
      (await _firebaseService.getCollection(
        collectionName: FirebaseCollections.members,
      )).map(ManagedUserModel.fromJson).toList();

  @override
  Future<void> createUser({
    required String email,
    required String displayName,
    required String temporaryPassword,
    required String role,
    required Map<String, bool> permissions,
  }) async {
    final emailKey = _key(email);
    if (emailKey.isEmpty || !emailKey.contains('@')) {
      throw StateError('أدخل بريداً إلكترونياً صحيحاً.');
    }
    final organizationId = _authService.organizationId;
    if (organizationId == null || organizationId.isEmpty) {
      throw StateError('لا توجد مؤسسة مرتبطة بالحساب الحالي.');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'id': emailKey,
      'email': emailKey,
      'displayName': displayName.trim(),
      'role': role,
      'permissions': permissions,
      'active': true,
      'organizationId': organizationId,
      'createdAtMillis': now,
      'updatedAtMillis': now,
      'createdBy': _firebaseService.currentUserId,
      'onboardingNote':
          'Create the account separately with Firebase Authentication. '
          'The supplied temporary password is never stored in Firestore.',
    };
    final directoryRef = _firebaseService
        .rootCollectionRef(FirebaseCollections.membershipDirectory)
        .doc(emailKey);
    final memberRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.members)
        .doc(emailKey);
    await _firebaseService.runTransaction((transaction) async {
      final existing = await transaction.get(directoryRef);
      if (existing.exists &&
          existing.data()?['organizationId'] != organizationId) {
        throw StateError('هذا البريد مرتبط بمؤسسة أخرى.');
      }
      transaction.set(directoryRef, data);
      transaction.set(memberRef, data);
    });
  }

  @override
  Future<void> updateAccess({
    required String uid,
    required String role,
    required Map<String, bool> permissions,
  }) async {
    final memberRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.members)
        .doc(uid);
    final member = await _firebaseService.getDocument(
      collectionName: FirebaseCollections.members,
      documentId: uid,
    );
    if (member == null) throw StateError('عضوية المستخدم غير موجودة.');
    final email = _key('${member['email'] ?? ''}');
    if (email.isEmpty) throw StateError('بريد العضوية غير موجود.');
    final now = DateTime.now().millisecondsSinceEpoch;
    final updates = {
      'role': role,
      'permissions': permissions,
      'updatedAtMillis': now,
    };
    await _firebaseService.runTransaction((transaction) async {
      transaction.update(memberRef, updates);
      transaction.update(
        _firebaseService
            .rootCollectionRef(FirebaseCollections.membershipDirectory)
            .doc(email),
        updates,
      );
    });
  }
}
