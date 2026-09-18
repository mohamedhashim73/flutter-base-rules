part of '../services.dart';

// import 'package:base/core/constants/strings.dart';
// import 'package:base/core/services/logging_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class FirebaseService {
//   const FirebaseService._();

//   static int pageSize = 5;
//   static FirebaseFirestore get firestore => FirebaseFirestore.instance;

//   static Future<DocumentSnapshot?> getDocument({
//     required String collectionName,
//     required String documentId,
//   }) async {
//     try {
//       return await firestore.collection(collectionName).doc(documentId).get();
//     } on FirebaseException catch (_) {
//       return null;
//     } catch (_) {
//       return null;
//     }
//   }

//   static Stream<DocumentSnapshot<Map<String, dynamic>>> watchDocument({
//     required String collectionName,
//     required String documentId,
//   }) {
//     return firestore.collection(collectionName).doc(documentId).snapshots();
//   }

//   static Future<T?> runTransaction<T>(
//     Future<T> Function(Transaction transaction) action,
//   ) async {
//     try {
//       return await firestore.runTransaction(action);
//     } on FirebaseException {
//       rethrow;
//     } catch (_) {
//       rethrow;
//     }
//   }

//   static Stream<QuerySnapshot<Map<String, dynamic>>> watchCollection({
//     required String collectionName,
//     Map<String, dynamic>? equalFilters,
//     Map<String, dynamic>? notEqualFilters,
//     String? orderBy,
//     bool descending = true,
//     int? limit,
//   }) {
//     Query<Map<String, dynamic>> query = firestore.collection(collectionName);

//     if (equalFilters != null) {
//       for (final entry in equalFilters.entries) {
//         query = query.where(entry.key, isEqualTo: entry.value);
//       }
//     }

//     if (notEqualFilters != null) {
//       for (final entry in notEqualFilters.entries) {
//         query = query.where(entry.key, isNotEqualTo: entry.value);
//       }
//     }

//     if (orderBy != null) {
//       query = query.orderBy(orderBy, descending: descending);
//     }

//     if (limit != null) {
//       query = query.limit(limit);
//     }

//     return query.snapshots();
//   }

//   static Future<int?> getCollectionDocsCount({
//     required String collectionName,
//     Map<String, dynamic>? equalFilters,
//     Map<String, RangeFilterEntity>? rangeFilters,
//   }) async {
//     try {
//       final snapshot = await getCollection(
//         collectionName: collectionName,
//         equalFilters: equalFilters,
//         rangeFilters: rangeFilters,
//       );

//       return snapshot.docs.length;
//     } on FirebaseException catch (_) {
//       return null;
//     } catch (_) {
//       return null;
//     }
//   }

//   static Future<QuerySnapshot<Map<String, dynamic>>> getCollection({
//     required String collectionName,
//     Map<String, dynamic>? equalFilters,
//     Map<String, List<dynamic>>? whereInFilters,
//     Map<String, RangeFilterEntity>? rangeFilters,
//     String? orderBy,
//     bool descending = true,
//     int? limit,
//     DocumentSnapshot<Map<String, dynamic>>? startAfter,
//     DocumentSnapshot<Map<String, dynamic>>? endAt,
//   }) {
//     LoggingService.showMsg("Get Collection $collectionName | Limit $limit");
//     Query<Map<String, dynamic>> query = firestore.collection(collectionName);

//     if (equalFilters != null) {
//       for (final entry in equalFilters.entries) {
//         query = query.where(entry.key, isEqualTo: entry.value);
//       }
//     }

//     if (whereInFilters != null) {
//       for (final entry in whereInFilters.entries) {
//         query = query.where(entry.key, whereIn: entry.value);
//       }
//     }

//     if (rangeFilters != null) {
//       for (final entry in rangeFilters.entries) {
//         final range = entry.value;

//         if (range.from != null) {
//           query = query.where(range.key, isGreaterThanOrEqualTo: range.from);
//         }

//         if (range.to != null) {
//           query = query.where(range.key, isLessThanOrEqualTo: range.to);
//         }
//       }
//     }

//     if (orderBy != null) {
//       query = query.orderBy(orderBy, descending: descending);
//     }

//     if (startAfter != null) {
//       query = query.startAfterDocument(startAfter);
//     }

//     if (endAt != null) {
//       query = query.endAtDocument(endAt);
//     }

//     if (limit != null) {
//       query = query.limit(limit);
//     }

//     return query.get();
//   }

//   /// Creates a document with an auto-generated id
//   /// and saves the id inside the document.
//   static Future<String?> addDocument({
//     required String collectionName,
//     required Map<String, dynamic> data,
//   }) async {
//     final reference = firestore.collection(collectionName).doc();

//     await reference.set({...data, 'id': reference.id});

//     return reference.id;
//   }

//   static Future<bool> setDocument({
//     required String collectionName,
//     required String documentId,
//     required Map<String, dynamic> data,
//   }) async {
//     try {
//       await firestore.collection(collectionName).doc(documentId).set(data);

//       return true;
//     } on FirebaseException catch (_) {
//       return false;
//     } catch (_) {
//       return false;
//     }
//   }

//   static Future<bool> updateDocument({
//     required String collectionName,
//     required String documentId,
//     required Map<String, dynamic> data,
//   }) async {
//     try {
//       await firestore.collection(collectionName).doc(documentId).update(data);

//       return true;
//     } on FirebaseException catch (_) {
//       return false;
//     } catch (_) {
//       return false;
//     }
//   }

//   static Future<bool> deleteDocument({
//     required String collectionName,
//     required String documentId,
//   }) async {
//     try {
//       await firestore.collection(collectionName).doc(documentId).delete();

//       return true;
//     } on FirebaseException catch (_) {
//       return false;
//     } catch (_) {
//       return false;
//     }
//   }

// }
