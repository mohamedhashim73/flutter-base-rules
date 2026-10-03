# Shimmer / Skeleton Loading Rules

Loading placeholders for the app. Implemented and verified across **every list page** in the app (stores, payments/history, people, person expenses, expenses, devices/sub-devices, categories, subcategories, invoices, statistics). Follow this pattern for any new page — it is the single source of truth.

---

## 1. Core colors (AppColors — `core/theme/app_colors.dart`)

```dart
static Color kShimmer   = const Color(0xFFF6F7F9); // primary shimmer bar fill
static Color kShimmerBg = const Color(0xFFE3E5E8); // secondary / darker block fill
```

Rules:
- **Never** use `const` constructors on widgets that contain `kShimmer`/`kShimmerBg` colors unless the color reference itself is const (`AppColors.kShimmer` is `static const` — the `Icon`/`Color` usage can stay const).
- When you need a *container background* for a shimmer block, use `AppColors.kShimmerBg.withValues(alpha: 0.5–0.9)` (light blocks look wrong with solid dark fill).
- Do NOT use deprecated `withOpacity()` — use `.withValues(alpha: x)`.

## 2. The atomic shimmer block (`core/components/shimmer_widgets/shimmer_card_widget.dart`)

```dart
class ShimmerItemWidget extends StatelessWidget {
  const ShimmerItemWidget({
    super.key,
    this.height, this.width, this.color, this.widget,
    this.radius, this.borderIsOn = true,
  });
}
```

- Renders a rounded `Container`; default color `AppColors.kShimmer`, default radius `AppConstants.kMainRadius`, default border `AppConstants.kSkeletonLoadingBorder`.
- Use for every grey bar/block inside a card:
  - `ShimmerItemWidget(width: 120, height: 14)` → a text-line bar
  - `ShimmerItemWidget(width: 44, height: 44, radius: 22)` → avatar/circle
  - `ShimmerItemWidget(width: 70, height: 10, borderIsOn: false)` → small pill without border

## 3. One shimmer widget per entity-card (mirror the real card layout)

Create a dedicated stateless widget per card type, placed next to the real card widget:

- `stores:    widgets/store_card_shimmer_widget.dart       (StoreCardShimmerWidget)`
- `payments:  widgets/store_payment_card_shimmer_widget.dart (StorePaymentCardShimmerWidget)`
- `people:    widgets/person_card_shimmer_widget.dart      (PersonCardShimmerWidget)`
- `expenses:  widgets/expense_card_shimmer_widget.dart     (ExpenseCardShimmerWidget)`
- `inventory: widgets/device_card_shimmer_widget.dart      (DeviceCardShimmerWidget)`
- `inventory: widgets/category_card_shimmer_widget.dart    (CategoryCardShimmerWidget)`
- `inventory: widgets/subcategory_card_shimmer_widget.dart (SubcategoryCardShimmerWidget)`
- `invoices:  core/components/invoice_widgets/invoice_card_shimmer_widget.dart (InvoiceCardShimmerWidget)`
- `statistics:widgets/period_card_shimmer_widget.dart      (PeriodCardShimmerWidget)`

Shimmer-widget conventions:
- Use `Theme.of(context).cardColor` + `AppConstants.kMainBorder` + `context.cardPadding` + `context.main` radius — **same container shell as the real card**, so layout height is identical (no jump when real data arrives).
- Only the inner content is grey blocks; the outer card keeps real colors.
- Mirror real spacing: avatars, label heights, secondary lines, trailing icons/chevrons, badges/pills, and any amount rows.
- Icons inside shimmer (chevron/delete/notes) use `color: AppColors.kShimmer`.

## 4. Wiring into the paginated list — `PaginatedListviewWidget`

File: `core/components/custom_listview_widgets/custom_listview_widget.dart`

Two modes — production flags on the widget:

1. **Whole-list shimmer (initial load):** `shimmerListIsEnabled: true` → renders `ShimmerListViewWidget` (N copies of `shimmerWidget`, default count `FirebaseService.pageSize` = 10). Use when there is zero data yet (first load / full refresh).
2. **Trailing pagination shimmer:** `shimmerListIsEnabled: false` + `shimmerItemIsEnabled: true`
   - List shows real items; the final row (`index == length`) renders `shimmerWidget` while more pages are being fetched.
   - Set `shimmerItemIsEnabled: false` once `length == count` (no more pages) → trailing row becomes `SizedBox`.

Also handled automatically:
- `_scheduleOverflowCheck()` force-wakes the scroll listener when the list fits on screen but more pages exist.
- Always pass the page's `ScrollController` so the page can init/dispose scroll + listener.

> **Padding:** when the list is built through `DataStateBuilderWidget` (states: loading/success/error/empty), pass `padding` to it — that padding is forwarded to `ShimmerListViewWidget` (`DataStateBuilderWidget.padding` → `ShimmerListViewWidget(padding:)`, see `core/components/data_state_widgets/data_state_handler_widget.dart`). So the shimmer list and the real list share the same `context.scaffoldPadding`-based padding and align identically. Do not wrap the shimmer separately with a different padding.

Example wiring (every list page follows this):
```dart
PaginatedListviewWidget(
  count: cubit.counter,                    // total available
  length: items.length,                    // currently visible count
  shimmerWidget: const StoreCardShimmerWidget(), // trailing-pagination skeleton
  shimmerItemIsEnabled: items.length < cubit.counter, // false at end
  shimmerListIsEnabled: state is LoadingState,       // full skeleton while loading first page
  scrollController: cubit.scrollController.normal,   // page-owned controller (init/dispose in page lifecycle)
  itemBuilder: (index) => StoreCard(...),
)
```

Toggle which of the two shimmer modes is on:
- `shimmerListIsEnabled: true`  → full-screen shimmer list (loading).
- `shimmerListIsEnabled: false` → real items list; the shimmer shows as the trailing loader row.

## 5. Legacy list wrapper (older pages) — `CustomListviewWidget`

```dart
CustomListviewWidget(
  isEmpty: ...,
  shimmerShownCondition: <bool>,  // while true, itemBuilder is bypassed
  shimmerWidget: StoreCardShimmerWidget(),
  length: items.length,
  itemBuilder: ...,
)
```
When `shimmerShownCondition` is true it renders `shimmerCount` (default 6) shimmer cards instead of real items. New pages should prefer `PaginatedListviewWidget`; keep `CustomListviewWidget` only for lists that don't need pagination callbacks.

## 6. Page integration checklist
- [ ] Shimmer widget exists for each entity card (mirrors real card container exactly).
- [ ] `kShimmer`/`kShimmerBg` colors used (no arbitrary grey), `.withValues()` not `.withOpacity()`.
- [ ] `PaginatedListviewWidget` receives `shimmerWidget`, both shimmer flags, and the page `ScrollController`.
- [ ] Initial loading shows full skeleton list; trailing pagination shows single shimmer row; end-of-list shows nothing.
- [ ] When using `DataStateBuilderWidget`, its `padding` is reused by the shimmer list — single source of padding.
- [ ] Empty state handled by `EmptyViewWidget` (via `isEmpty`), not by shimmer.
- [ ] No `const` on widgets referencing non-const color instances.

## Verified references (app codebase)
- Colors: `core/theme/app_colors.dart:47-48`
- Atomic block: `core/components/shimmer_widgets/shimmer_card_widget.dart`
- List wrapper + helpers: `core/components/custom_listview_widgets/custom_listview_widget.dart`
- State wrapper (padding → shimmer list): `core/components/data_state_widgets/data_state_handler_widget.dart`
- Page examples: `views/stores/stores_page.dart`, `views/payments/payments_page.dart`, `views/people/people_page.dart`, `views/expenses/expenses_page.dart`, `views/inventory/subcategories_list_page.dart`, `views/statistics/statistics_page.dart`, `views/sales_invoice/sales_invoices_page.dart`, `views/purchase_invoice/purchase_invoices_page.dart`