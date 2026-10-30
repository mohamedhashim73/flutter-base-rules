import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:base/core/constants/domain/firebase_collections.dart';
import 'firebase_auth_service.dart';

class FirebaseService {
  FirebaseService(this._authService) : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuthService _authService;

  /// Generates a Firestore-compatible identifier without performing a read or write.
  /// Callers still persist the returned id in the document payload.
  String newDocumentId() =>
      _firestore.collection(FirebaseCollections.documentIds).doc().id;

  String get currentUserId {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw StateError('An authenticated user is required.');
    }
    return userId;
  }

  CollectionReference<Map<String, dynamic>> rootCollectionRef(
    String collectionName,
  ) => _firestore.collection(collectionName);

  CollectionReference<Map<String, dynamic>> scopedCollectionRef(
    String collectionName,
  ) {
    final organizationId = _authService.organizationId;
    if (organizationId != null && organizationId.isNotEmpty) {
      return _firestore
          .collection(FirebaseCollections.organizations)
          .doc(organizationId)
          .collection(collectionName);
    }
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(currentUserId)
        .collection(collectionName);
  }

  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionName,
    Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> ref,
    )?
    query,
  }) async {
    final ref = scopedCollectionRef(collectionName);
    final snapshot = await (query?.call(ref) ?? ref).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>?> getDocument({
    required String collectionName,
    required String documentId,
  }) async {
    final snapshot = await scopedCollectionRef(
      collectionName,
    ).doc(documentId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return {'id': snapshot.id, ...snapshot.data()!};
  }

  Future<void> setDocument({
    required String collectionName,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return scopedCollectionRef(
      collectionName,
    ).doc(documentId).set(data, SetOptions(merge: true));
  }

  Future<void> updateDocument({
    required String collectionName,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return scopedCollectionRef(collectionName).doc(documentId).update(data);
  }

  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) {
    return _firestore.runTransaction(action);
  }

  Future<void> runBatch(void Function(WriteBatch batch) action) {
    final batch = _firestore.batch();
    action(batch);
    return batch.commit();
  }
}
