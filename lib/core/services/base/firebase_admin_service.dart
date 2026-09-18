// import 'dart:convert';

// import 'package:base/core/services/base/firebase_service.dart';
// import 'package:base/core/services/logging_service.dart';

// /// One-off and maintenance operations against Firestore.
// /// These are dev/admin utilities — never called from normal app flows.
// class FirebaseAdminService {
//   /// Reads every document from every known collection and prints the full
//   /// backup as a JSON string via [LoggingService].
//   ///
//   /// Each top-level key in the JSON is a collection name; its value is a list
//   /// of document data maps (with Timestamps converted to ISO-8601 strings and
//   /// [FieldValue] sentinels replaced with `null` so the output is valid JSON).
//   static Future<void> backupAllCollections() async {
//     final allCollections = sl<Collections>().allCollections;
//     final backup = <String, dynamic>{};
//     for (final collection in allCollections) {
//       try {
//         final snapshot = await FirebaseService.getCollection(
//           collectionName: collection,
//         );
//         backup[collection] = snapshot.docs
//             .map((doc) => _sanitizeMap(doc.data()))
//             .toList();
//         LoggingService.showMsg(
//           'backupAllCollections: fetched ${snapshot.docs.length} docs from "$collection"',
//         );
//       } catch (e) {
//         LoggingService.showMsg(
//           'backupAllCollections: failed to fetch "$collection" — $e',
//         );
//         backup[collection] = [];
//       }
//     }

//     final json = const JsonEncoder.withIndent('  ').convert(backup);
//     LoggingService.showMsg(
//       '=== BACKUP START ===\n$json\n=== BACKUP END At ${DateTime.now()}===',
//     );
//   }

//   /// Recursively converts a Firestore data map to a plain JSON-safe map.
//   /// - [Timestamp] → ISO-8601 string
//   /// - [DocumentReference] → its path string
//   /// - Nested [Map] → recursed
//   /// - Nested [List] → each element recursed
//   /// - Everything else is left as-is (strings, numbers, booleans, null).
//   static dynamic _sanitizeValue(dynamic value) {
//     if (value is Timestamp) {
//       return value.toDate().toIso8601String();
//     }
//     if (value is DocumentReference) {
//       return value.path;
//     }
//     if (value is Map<String, dynamic>) {
//       return _sanitizeMap(value);
//     }
//     if (value is List) {
//       return value.map(_sanitizeValue).toList();
//     }
//     return value;
//   }

//   static Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
//     return map.map((key, value) => MapEntry(key, _sanitizeValue(value)));
//   }

//   /// Deletes every document in every known collection.
//   /// Documents are deleted in batches of 500 (Firestore batch limit).
//   /// Only operates on collections whose name contains "dev" as a safety guard.
//   /// Logs progress per collection via [LoggingService].
//   static Future<void> deleteAllCollections() async {
//     for (final collection in sl<Collections>().allCollections) {
//       try {
//         final snapshot = await FirebaseService.getCollection(
//           collectionName: collection,
//         );
//         final docs = snapshot.docs;
//         if (docs.isEmpty) {
//           LoggingService.showMsg(
//             'deleteAllCollections: "$collection" is already empty',
//           );
//           continue;
//         }

//         const batchSize = 500;
//         for (var i = 0; i < docs.length; i += batchSize) {
//           final batch = FirebaseService.firestore.batch();
//           final chunk = docs.skip(i).take(batchSize);
//           for (final doc in chunk) {
//             batch.delete(doc.reference);
//           }
//           await batch.commit();
//         }

//         LoggingService.showMsg(
//           'deleteAllCollections: deleted ${docs.length} docs from "$collection"',
//         );
//       } catch (e) {
//         LoggingService.showMsg(
//           'deleteAllCollections: failed to delete "$collection" — $e',
//         );
//       }
//     }
//     LoggingService.showMsg('deleteAllCollections: done');
//   }

//   /// Loops over every document in [collectionName] and removes [fieldKey]
//   /// from each document using [FieldValue.delete()].
//   /// Only touches documents that actually have the field — skips the rest.
//   /// Uses batched writes of 500 per commit for performance.
//   static Future<void> deleteFieldFromCollection({
//     required String collectionName,
//     required String fieldKey,
//   }) async {
//     final label = 'deleteFieldFromCollection[$collectionName.$fieldKey]';
//     try {
//       final snap = await FirebaseService.getCollection(
//         collectionName: collectionName,
//       );

//       LoggingService.showMsg(
//         '$label: found ${snap.docs.length} docs in "$collectionName"',
//       );

//       // Only docs that actually have the field
//       final toUpdate = snap.docs
//           .where((doc) => doc.data().containsKey(fieldKey))
//           .toList();

//       if (toUpdate.isEmpty) {
//         LoggingService.showMsg(
//           '$label: no docs contain "$fieldKey" — nothing to do',
//         );
//         return;
//       }

//       LoggingService.showMsg(
//         '$label: ${toUpdate.length} docs have "$fieldKey" — removing',
//       );

//       const batchSize = 500;
//       int removed = 0;

//       for (var i = 0; i < toUpdate.length; i += batchSize) {
//         final batch = FirebaseService.firestore.batch();
//         final chunk = toUpdate.skip(i).take(batchSize);
//         for (final doc in chunk) {
//           batch.update(doc.reference, {fieldKey: FieldValue.delete()});
//           removed++;
//         }
//         await batch.commit();
//         LoggingService.showMsg(
//           '$label: committed batch ${(i ~/ batchSize) + 1}',
//         );
//       }

//       LoggingService.showMsg(
//         '$label: done — removed "$fieldKey" from $removed docs in ${(toUpdate.length / batchSize).ceil()} batch(es)',
//       );
//     } on FirebaseException catch (e) {
//       LoggingService.showMsg('$label: FirebaseException ${e.code}');
//     } catch (e) {
//       LoggingService.showMsg('$label: Exception $e');
//     }
//   }
// }
