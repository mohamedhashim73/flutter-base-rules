part of '../services.dart';

// import 'dart:async';

// import 'package:base/core/enums/request_status_enum.dart';
// import 'package:base/core/errors/errors_msg_handler.dart';
// import 'package:base/core/services/base/incremental_sync_merger.dart';
// import 'package:base/core/services/logging_service.dart';
// import 'package:base/model/base/base_response.dart';
// import 'package:base/model/base/request_state.dart';

// /// Incremental Sync Helper with SharedPreferences Cache Support
// ///
// /// **Three-tier caching strategy:**
// /// 1. In-memory cache (`current()`)
// /// 2. SharedPreferences cache (`cachedCurrent()`)
// /// 3. Firebase sync (`syncHandler`)
// ///
// /// **Behavior:**
// /// - First load: Fetch from SharedPreferences → try incremental from lastSyncAt → fallback to full fetch
// /// - Subsequent loads (no refresh): Use in-memory → incremental by lastSyncAt
// /// - Restart without edits: Load from SharedPreferences → NO Firebase read (if lastSyncAt exists)
// ///
// class IncrementalSyncHelper {
//   const IncrementalSyncHelper._();

//   static final Map<String, bool> _fetchingByLabel = {};

//   static Future<void>
//   execute<S extends RequestState, T extends LoadableResponse>({
//     required void Function(S state) emit,
//     required S Function({RequestStatus? status, String? message}) state,
//     required T? Function() current,
//     required void Function(T? value) setCurrent,
//     required DateTime? Function() getLastSyncAt,
//     required Future<void> Function(DateTime syncAt) setLastSyncAt,
//     required bool refresh,
//     T? Function()? cachedCurrent,
//     // Single handler: lastSyncAt=null means full fetch, non-null means incremental
//     required FutureOr<T?> Function(DateTime? lastSyncAt) syncHandler,
//     // Unique label for this sync operation (prevents blocking between different cubits)
//     String syncLabel = 'default',
//   }) async {
//     // Prevent concurrent requests for THIS label (unless refresh=true)
//     final isFetching = _fetchingByLabel[syncLabel] ?? false;
//     if (isFetching && !refresh) return;

//     var currentResponse = current();

//     // Determine what to do
//     final needsFetch =
//         refresh || currentResponse == null || currentResponse.data == null;

//     _fetchingByLabel[syncLabel] = true;
//     emit(state(status: RequestStatus.loading));

//     try {
//       DateTime? syncAtParam;

//       if (!needsFetch) {
//         // We have in-memory data, use lastSyncAt for incremental
//         syncAtParam = getLastSyncAt();
//         if (syncAtParam == null) {
//           LoggingService.showMsg(
//             '[IncrementalSync] In-memory data exists but no lastSyncAt - full fetch',
//           );
//           syncAtParam = null;
//         } else {
//           LoggingService.showMsg(
//             '[IncrementalSync] In-memory exists - incremental sync since: $syncAtParam',
//           );
//         }
//       } else if (refresh) {
//         // Explicit refresh requested: bypass cache and do full fetch
//         LoggingService.showMsg(
//           '[IncrementalSync] refresh=true - bypassing cache, full fetch',
//         );
//         syncAtParam = null;
//       } else {
//         // No in-memory data, try SharedPreferences cache
//         if (cachedCurrent != null) {
//           currentResponse = cachedCurrent();
//           if (currentResponse != null) {
//             setCurrent(currentResponse);
//             LoggingService.showMsg(
//               '[IncrementalSync] ✓ Loaded from SharedPreferences cache',
//             );

//             final lastSyncAt = getLastSyncAt();
//             if (lastSyncAt != null) {
//               LoggingService.showMsg(
//                 '[IncrementalSync] Cache hit + lastSyncAt exists - incremental sync since: $lastSyncAt',
//               );
//               syncAtParam = lastSyncAt;
//             } else {
//               LoggingService.showMsg(
//                 '[IncrementalSync] Cache hit but no lastSyncAt - full fetch',
//               );
//               syncAtParam = null;
//             }
//           } else {
//             LoggingService.showMsg('[IncrementalSync] No cache - full fetch');
//             syncAtParam = null;
//           }
//         } else {
//           LoggingService.showMsg(
//             '[IncrementalSync] No cachedCurrent provided - full fetch',
//           );
//           syncAtParam = null;
//         }
//       }

//       final result = await syncHandler(syncAtParam);

//       if (result != null) {
//         setCurrent(result);
//         await setLastSyncAt(DateTime.now());
//         LoggingService.showMsg(
//           '[IncrementalSync] ✓ Sync successful - lastSyncAt updated',
//         );
//         emit(state(status: RequestStatus.success));
//       } else {
//         // Sync returned null - this is valid for empty results, not a failure
//         await setLastSyncAt(DateTime.now());
//         emit(state(status: RequestStatus.success));
//       }
//     } on FirebaseException catch (e) {
//       LoggingService.showMsg('[IncrementalSync] Firebase error: $e');
//       emit(
//         state(
//           status: RequestStatus.failure,
//           message: ErrorHandler.error(e),
//         ),
//       );
//     } catch (e) {
//       LoggingService.showMsg('[IncrementalSync] Error: $e');
//       emit(
//         state(
//           status: RequestStatus.failure,
//           message: ErrorHandler.error(e),
//         ),
//       );
//     } finally {
//       _fetchingByLabel[syncLabel] = false;
//     }
//   }

//   /// Query Firebase → Convert to models → Merge locally
//   ///
//   /// Combines Firebase query, data conversion, and incremental merge.
//   /// This avoids repeating query+convert logic in each cubit's _sync method.
//   ///
//   /// Usage:
//   /// ```dart
//   /// return await IncrementalSyncHelper.queryAndMerge<CategoryModel>(
//   ///   query: () => FirebaseService.getCollection(
//   ///     collectionName: Collections.categories,
//   ///     rangeFilters: lastSyncAt != null ? { ... } : null,
//   ///   ),
//   ///   mapper: (doc) => CategoryModel.fromJson({...doc.data(), 'id': doc.id}),
//   ///   items: categories,
//   ///   lastSyncAt: lastSyncAt,
//   ///   label: 'Categories',
//   ///   onSave: (items) => CacheManager.setCategories(items),
//   /// );
//   /// ```
//   static Future<ListData<T>?> queryAndMerge<T extends HasId>({
//     required Future<QuerySnapshot<Map<String, dynamic>>> Function() query,
//     required T Function(QueryDocumentSnapshot<Map<String, dynamic>>) mapper,
//     required List<T> items,
//     required DateTime? lastSyncAt,
//     required String label,
//     required Future<void> Function(List<T> items) onSave,
//     bool Function(T item)? isDeleted,
//     void Function(List<T> items)? onPostProcess,
//     void Function(List<T> items, DateTime syncTime)? onCacheUpdate,
//     void Function(List<T> items)? onPaginationUpdate,
//   }) async {
//     try {
//       final syncTime = DateTime.now();

//       final snapshot = await query();
//       final updated = snapshot.docs.map(mapper).toList();

//       final merged = await IncrementalSyncMerger.merge<T>(
//         items: items,
//         updated: updated,
//         lastSyncAt: lastSyncAt,
//         label: label,
//         onSave: onSave,
//         isDeleted: isDeleted,
//       );

//       // Post-process if provided (e.g., sorting, filtering)
//       onPostProcess?.call(merged);

//       // Update cache with sync timestamp
//       onCacheUpdate?.call(merged, syncTime);

//       // Update pagination manager
//       onPaginationUpdate?.call(merged);

//       return merged.isNotEmpty ? ListData(merged) : null;
//     } catch (e) {
//       LoggingService.showMsg('$label.queryAndMerge: $e');
//       rethrow;
//     }
//   }
// }
