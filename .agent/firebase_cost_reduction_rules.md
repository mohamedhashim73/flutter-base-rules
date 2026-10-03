# Firebase Cost Reduction Rules (Incremental Sync + Local Pagination)

This document defines the pattern used to keep Firebase read costs low while
still giving a reactive, paginated UI. It is the reference for building any
list/dashboard feature that will grow and be read frequently.

---

## 1. Core Idea

Never re-download everything on every screen open. Instead:

1. Serve data instantly from an **in-memory cache** (map in the cubit).
2. Fall back to a **SharedPreferences disk cache** on cold start.
3. Only then hit Firebase with an **incremental** query (`updatedAt > lastSyncAt`).
4. Render with **client-side pagination** inside an infinite `ListView`.

Result: one small Firestore query per open, and no changed documents when
nothing changed. A no-change incremental sync must also skip the large cache
payload write; only advance the lightweight marker.

---

## 2. Three-Tier Cache Architecture

Every list cubit keeps:

| Tier | Storage | Purpose |
| --- | --- | --- |
| 1 | cubit in-memory (`Map<String, Model>`) | instant UI for the session |
| 2 | SharedPreferences (`CachedData<T>`) | survive app restarts |
| 3 | Firebase (incremental by `updatedAt`) | get only what changed |

The sync marker is `lastSyncAt`. Persist it in a dedicated lightweight
SharedPreferences integer key per collection; keep the embedded JSON value as
a backward-compatible fallback for older cache entries. Updating a marker must
not re-encode and rewrite the entire cached collection.

**Restart without edits → NO Firebase read at all** (disk cache + marker exist).

---

## 3. Loading Flow (what to copy)

```
IncrementalSyncHelper.execute(...)
│
├─ if in-memory data exists  → incremental since lastSyncAt
├─ else if disk cache exists → load cache, then incremental since lastSyncAt
└─ else                     → full fetch
│
└─ syncHandler(lastSyncAt)   → queryAndMerge   (FirebaseService + merger)
```

Rules:
- `lastSyncAt == null` → full fetch (replace all items).
- `lastSyncAt != null` → Firestore query with `updatedAt >= lastSyncAt` range filter.
- Result is **merged** into the existing list by document id.
- Duplicate sync calls for the same `syncLabel` while in-flight are skipped.

---

## 4. Key Files (reference implementation)

Live, working examples — copy the pattern from these:

- `lib/core/services/base/incremental_sync_helper.dart`
  - `IncrementalSyncHelper.execute(...)` — the orchestration above.
  - `IncrementalSyncHelper.queryAndMerge<T>(...)` — query → map → merge → save → pagination update hook.
- `lib/core/services/base/incremental_sync_merger.dart`
  - `IncrementalSyncMerger.merge<T extends HasId>(...)` — replace on full fetch, merge by id on incremental, drop soft-deleted items.
- `lib/core/services/base/pagination_manager.dart`
  - `LocalPaginationManager<T, V>(pageSize, search, toVariants)` — search/filter + client-side pagination.
  - `applySearchWithItems(items)`, `appendPage(page)`, `hasNext`, `visibleItems`.
- `lib/core/services/base/search_manager.dart` / `scroll_manager.dart`
  - API-agnostic search + infinite-scroll trigger helpers.
- **Real cubit usage (read first):**
  - `lib/views/sales_invoice/controllers/sales_invoices_cubit/sales_invoices_cubit.dart`
  - `lib/views/people/controller/people_cubit/people/people_cubit.dart`
  - `lib/views/expenses/controller/expenses/expenses_cubit.dart`
  - `lib/views/inventory/controller/devices_cubit/devices/devices_cubit.dart`

---

## 5. Cubit Wiring Checklist

```dart
// 1. Pagination + search + scroll managers
late final LocalPaginationManager<Model, Model> _pagination;
final SearchManager search = SearchManager();
final ScrollManager scroll = ScrollManager();

// 2. fetch
IncrementalSyncHelper.execute<S, ListData<Model>>(
  emit: emit,
  state: S.new,
  current: () => _items.isNotEmpty ? ListData(_items) : null,
  setCurrent: (v) { _items = v?.data ?? []; ... },
  cachedCurrent: () => CacheManager.get...,      // disk cache loader
  getLastSyncAt: () => _cache?.lastSyncAt,
  setLastSyncAt: (at) async =>
      CacheManager.setCachedLastSyncAt(collectionLastSyncKey, at),
  refresh: refresh,
  syncHandler: (lastSyncAt) => _sync(lastSyncAt),
  syncLabel: 'FeatureName',
);

// 3. sync handler
Future<ListData<Model>?> _sync(DateTime? lastSyncAt) =>
  IncrementalSyncHelper.queryAndMerge<Model>(
    query: () => FirebaseService.getCollection(
      collectionName: Collections.xxx,
      rangeFilters: lastSyncAt != null ? { kUpdatedAt: RangeFilterEntity(...) } : null,
      orderBy: lastSyncAt == null ? kX : kUpdatedAt,
      descending: true,
    ),
    mapper: (doc) => Model.fromJson({...doc.data(), 'id': doc.id}),
    items: _items,
    lastSyncAt: lastSyncAt,
    label: 'FeatureName',
    onSave: (items) => CacheManager.set...,
    isDeleted: (item) => item.isDeleted,          // soft-delete filter
    onPostProcess: (items) => items.sort(...),
    onPaginationUpdate: (items) { _items = items; _pagination.applySearchWithItems(items); },
  );
```

UI side:
- `ListView.separated` bound to `visibleItems`.
- `notificationListener`/`scroll.onScroll` appends the next page near the end.
- Empty/loading/error handled via existing shared `data_state_widgets`.

---

## 6. Mandatory Rules

- ✅ Every write (add/update/invoice transaction) MUST set `updatedAt`.
- ✅ Soft delete = set `isDeleted: true` in Firestore, keep the doc, filter in merger.
- ✅ Search/filter/last-n filters run on the already-downloaded list — never re-query.
- ✅ Pagination is client-side; Firestore is NOT paginated on scroll.
- ✅ `syncLabel` unique per cubit so parallel syncs don't block each other.
- ❌ No raw `FirebaseFirestore.instance` in cubits; go through `FirebaseService`.
- ❌ No realtime listeners unless the feature truly needs live updates.

### Account/session boundary rule

- Logout must clear both persisted cache and every account-scoped Cubit's
  in-memory list and `_cache`/`lastSyncAt` marker.
- A singleton Cubit must not carry its previous account's sync marker into a
  later login. Resetting only the visible list is insufficient: the next
  load would incorrectly run an incremental query and could miss older
  documents or preserve data deleted while logged out.
- After an account boundary, the next load must use `lastSyncAt == null` and
  perform one full fetch. Normal loads within the same account continue to
  use the incremental `updatedAt` query and local pagination.
- If a sync can outlive logout, its result must be prevented from repopulating
  the previous account's in-memory state (for example with a session/generation
  guard). The shared in-flight protection must not block the first fetch of the
  new account.
- When loading a disk cache, filter `isDeleted == true` items before exposing
  the cache to the UI. This is a local operation and adds no Firebase reads.
  The normal incremental query must still fetch only documents changed after
  `lastSyncAt`; do not add a full collection read just to check deletions.
- A soft-delete write must update `updatedAt` in the same write/transaction.
  Hard deletion or manually changing `isDeleted` in the Firebase Console
  without updating `updatedAt` cannot be detected by an `updatedAt`-only query;
  use a full resync at an account boundary or update the tombstone timestamp.
- `IncrementalSyncMerger` must not call the large-cache `onSave` callback when
  an incremental query returns no documents. Save on a full fetch or whenever
  changed documents (including tombstones) were merged, while the caller
  updates only the dedicated sync marker for every completed query.

---

## 7. Why This Exists

Firestore charges per document read. Full re-fetch on every list open scales
linearly with data size and inflates cost immediately. The incremental pattern
reads ~1 doc per change; disk cache makes clean restarts free.
