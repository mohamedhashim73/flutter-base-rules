// import 'package:base/model/base/firebase_paginated_response.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class FirebasePaginatedData<T>
//     implements
//         FirebasePaginatedResponse<
//           List<T>,
//           FirebasePaginatedData<T>
//         > {
//   @override
//   final List<T> data;

//   @override
//   final DocumentSnapshot<Map<String, dynamic>>? lastDocument;

//   @override
//   final bool hasNext;

//   const FirebasePaginatedData({
//     required this.data,
//     required this.lastDocument,
//     required this.hasNext,
//   });

//   factory FirebasePaginatedData.fromSnapshot({
//     required QuerySnapshot<Map<String, dynamic>> snapshot,
//     required int limit,
//     required T Function(
//       DocumentSnapshot<Map<String, dynamic>> document,
//     ) mapper,
//   }) {
//     final hasNext = snapshot.docs.length > limit;

//     final visibleDocuments = snapshot.docs.take(limit).toList();

//     return FirebasePaginatedData<T>(
//       data: visibleDocuments.map(mapper).toList(),
//       lastDocument: visibleDocuments.isEmpty
//           ? null
//           : visibleDocuments.last,
//       hasNext: hasNext,
//     );
//   }

//   @override
//   FirebasePaginatedData<T> copyWithPagination({
//     required List<dynamic> data,
//     required DocumentSnapshot<Map<String, dynamic>>? lastDocument,
//     required bool hasNext,
//   }) {
//     return FirebasePaginatedData<T>(
//       data: data.cast<T>(),
//       lastDocument: lastDocument,
//       hasNext: hasNext,
//     );
//   }

//   FirebasePaginatedData<T> copyWith({
//     List<T>? data,
//     DocumentSnapshot<Map<String, dynamic>>? lastDocument,
//     bool? hasNext,
//   }) {
//     return FirebasePaginatedData<T>(
//       data: data ?? this.data,
//       lastDocument: lastDocument ?? this.lastDocument,
//       hasNext: hasNext ?? this.hasNext,
//     );
//   }

//   @override
//   String toString() {
//     return 'FirebasePaginatedData('
//         'dataLength: ${data.length}, '
//         'lastDocumentId: ${lastDocument?.id}, '
//         'hasNext: $hasNext'
//         ')';
//   }
// }