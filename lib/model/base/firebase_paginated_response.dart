// import 'package:base/model/base/base_response.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// abstract interface class FirebasePaginatedResponse<
//   T,
//   R extends FirebasePaginatedResponse<T, R>
// >
//     implements LoadableResponse<T> {
//   DocumentSnapshot<Map<String, dynamic>>? get lastDocument;

//   bool get hasNext;

//   R copyWithPagination({
//     required List<dynamic> data,
//     required DocumentSnapshot<Map<String, dynamic>>? lastDocument,
//     required bool hasNext,
//   });
// }