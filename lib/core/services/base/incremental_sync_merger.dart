
import 'package:base/core/services/logging_service.dart';

/// Base interface for items with an id
abstract class HasId {
  String get id;
}

/// Incremental Sync Merger
///
/// Handles common merge logic for incremental sync:
/// - Full fetch: replace all items
/// - Incremental: merge updates with existing
/// - Logging: track what changed
/// - Persistence: save merged data to cache
///
/// Usage:
/// ```dart
/// final merged = await IncrementalSyncMerger.merge<CategoryModel>(
///   items: categories,
///   updated: changedDocs.map((doc) => CategoryModel.fromJson(...)).toList(),
///   lastSyncAt: lastSyncAt,
///   label: 'Categories',
///   onSave: (items) => CacheManager.setCategories(items),
/// );
/// categories = merged;
/// ```
class IncrementalSyncMerger {
  const IncrementalSyncMerger._();

  /// Merge updated items with existing list
  ///
  /// - If [lastSyncAt] is null: Full fetch (replace all)
  /// - If [lastSyncAt] is non-null: Incremental (merge updates)
  static Future<List<T>> merge<T extends HasId>({
    required List<T> items,
    required List<T> updated,
    required DateTime? lastSyncAt,
    required String label,
    required Future<void> Function(List<T> items) onSave,
    bool Function(T item)? isDeleted,
  }) async {
    List<T> result;

    if (updated.isEmpty) {
      LoggingService.showMsg(
        '[$label] Incremental: no changes, keeping ${items.length} items',
      );
      result = items;
    } else if (lastSyncAt == null) {
      result = updated;
      LoggingService.showMsg('[$label] Full fetch: ${result.length} items');
    } else {
      final merged = <String, T>{for (final item in items) item.id: item};
      for (final item in updated) {
        merged[item.id] = item;
      }
      result = merged.values.toList();
      LoggingService.showMsg(
        '[$label] Incremental: fetched ${updated.length} changes, total now ${result.length}',
      );
    }

    // Remove deleted items from cache so they never appear again
    if (isDeleted != null) {
      final before = result.length;
      result = result.where((item) => !isDeleted(item)).toList();
      final removed = before - result.length;
      if (removed > 0) {
        LoggingService.showMsg('[$label] Removed $removed deleted items');
      }
    }

    await onSave(result);
    return result;
  }
}
