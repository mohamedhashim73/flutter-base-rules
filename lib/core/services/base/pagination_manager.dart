import 'package:base/core/services/base/search_manager.dart';
import 'package:base/model/base/pagination_model.dart';

/// Local Pagination Manager
///
/// Handles local (in-memory) pagination and filtering for lists.
/// Used for paginating data AFTER full fetch from Firebase.
/// Does NOT query Firebase - purely local client-side pagination.
///
/// Combines:
/// - Search query filtering
/// - Category/status filtering
/// - Model-to-variant conversion (flexible via toVariants callback)
/// - Local pagination (split results into pages)
/// - Pagination metadata tracking
///
/// Generic usage - works with any model types:
/// - T = Input model type (ProductModel, OrderModel, etc)
/// - V = Output variant type (ProductVariantEntryModel, OrderModel, etc)
///
/// Usage (Products with search + category filter):
/// ```dart
/// final manager = LocalPaginationManager<ProductModel, ProductVariantEntryModel>(
///   pageSize: 6,
///   search: searchManager,
///   toVariants: (products) => _deriveVariants(products, selectedCategoryId),
/// );
///
/// manager.applySearchWithItems(_products);
/// manager.appendPage(currentPage);
/// ```
///
/// Usage (Orders with status filter):
/// ```dart
/// final manager = LocalPaginationManager<OrderModel, OrderModel>(
///   pageSize: 10,
///   search: searchManager,
///   toVariants: (orders) => _filterByStatus(orders, selectedStatus),
/// );
///
/// manager.applySearchWithItems(_allOrders);
/// manager.appendPage(1);
/// ```
class LocalPaginationManager<T, V> {
  final int pageSize;
  final SearchManager search;
  final List<V> Function(List<T> items) toVariants;

  List<V> filteredItems = [];
  List<V> visibleItems = [];
  PaginationModel? pagination;

  LocalPaginationManager({
    required this.pageSize,
    required this.search,
    required this.toVariants,
  });

  /// Apply search and filter to derive filtered items from empty list
  void applySearch() {
    filteredItems = toVariants.call([]);
    visibleItems = [];
    pagination = null;
    appendPage(1);
  }

  /// Apply search and filter to derive filtered items from provided items
  /// This is the main method - call after data changes
  void applySearchWithItems(List<T> items) {
    filteredItems = toVariants.call(items);
    visibleItems = [];
    pagination = null;
    appendPage(1);
  }

  /// Append/paginate to a specific page number
  /// Call when user scrolls or clicks "load more"
  void appendPage(int page) {
    final total = filteredItems.length;
    final totalPages = (total / pageSize)
        .ceil()
        .clamp(1, double.maxFinite)
        .toInt();
    final p = page.clamp(1, totalPages);
    final start = (p - 1) * pageSize;
    final end = (start + pageSize).clamp(0, total);
    if (start >= total) return;
    final chunk = filteredItems.sublist(start, end);
    visibleItems = p == 1 ? List<V>.from(chunk) : [...visibleItems, ...chunk];
    pagination = PaginationModel(
      total: total,
      count: visibleItems.length,
      perPage: pageSize,
      currentPage: p,
      totalPages: totalPages,
    );
  }

  /// Clear pagination
  void reset() {
    filteredItems = [];
    visibleItems = [];
    pagination = null;
  }

  /// Get current page number
  int get currentPage => pagination?.currentPage ?? 1;

  /// Check if has more pages
  bool get hasNext => pagination?.hasNext ?? false;

  /// Get total items count
  int get totalCount => pagination?.total ?? 0;
}
