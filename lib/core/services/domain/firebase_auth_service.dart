import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:base/core/constants/domain/firebase_collections.dart';

class FirebaseAuthService {
  FirebaseAuthService() : _auth = FirebaseAuth.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> _membership = const {};

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await refreshMembership();
    return result;
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await refreshMembership();
    return result;
  }

  Future<void> signOut() async {
    _membership = const {};
    await _auth.signOut();
  }

  Future<Map<String, dynamic>> refreshMembership() async {
    final user = currentUser;
    if (user == null) {
      _membership = const {};
      return _membership;
    }
    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      _membership = const {};
      return _membership;
    }
    final snapshot = await _firestore
        .collection(FirebaseCollections.membershipDirectory)
        .doc(email)
        .get();
    final data = snapshot.data();
    _membership = data != null && data['active'] == true
        ? Map<String, dynamic>.from(data)
        : const {};
    return _membership;
  }

  bool get hasMembership =>
      organizationId != null && organizationId!.isNotEmpty;

  String? get organizationId => _membership['organizationId'] as String?;
  String? get role => _membership['role'] as String?;

  Future<bool> hasRole(String role) async {
    if (_membership.isEmpty) await refreshMembership();
    return _membership['role'] == role;
  }

  Future<bool> hasPermission(String permission) async {
    if (_membership.isEmpty) await refreshMembership();
    final permissions = _membership['permissions'];
    return permissions is Map && permissions[permission] == true;
  }
}
