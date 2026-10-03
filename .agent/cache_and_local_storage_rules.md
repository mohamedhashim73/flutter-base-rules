# Cache Layer & Local Storage Architecture Rules

This document defines how local caching, SharedPreferences usage, and cache flow should be structured across the application.

---

# 1. Core Principle

Caching is a centralized infrastructure layer.

UI MUST NEVER:
- access SharedPreferences directly
- save cache manually
- parse cached JSON
- clear cache manually

Cubit communicates ONLY with:
- CacheManager
- CacheHelper

---

# 2. Cache Layer Structure

## Core Files

Located inside:

txt
core/
 ├── network/
 │    ├── cache_helper.dart
 │    ├── cache_manager.dart
`

---

# 3. CacheHelper Responsibility

`CacheHelper` is the low-level storage wrapper.

Responsible for:

* set/get primitive values
* remove items
* clear cache
* SharedPreferences abstraction

---

## Allowed Types

dart
String
int
double
bool


---

## Example

dart
await CacheHelper.setString(
  key: AppStrings.token,
  value: token,
);


---

# 4. CacheManager Responsibility

`CacheManager` is the high-level app cache layer.

Responsible for:

* caching models
* converting models to/from JSON
* feature-specific cache access
* centralized cached data handling

---

## Example

dart
await CacheManager.setUser(user);


dart
final user = CacheManager.getUser();


---

# 5. Architecture Rule

## Correct Flow

txt
UI
 → Cubit
   → CacheManager
     → CacheHelper
       → SharedPreferences


---

## Forbidden

❌ SharedPreferences inside UI
❌ SharedPreferences inside Cubits
❌ Manual jsonEncode/jsonDecode inside UI
❌ Primitive cache handling outside CacheHelper

---

# 6. Primitive Cache Rules

Primitive values belong inside:

dart
CacheHelper


Examples:

dart
setString()
getString()
insertBool()
getBool()


---

# 7. Model Cache Rules

Models MUST be cached inside:

dart
CacheManager


---

## Example

dart
static Future<void> setUser(UserModel user) async {
  await _sharedPreferences.setString(
    AppStrings.kCachedUser,
    jsonEncode(user.toJson(isCache: true)),
  );
}


---

## Retrieval Example

dart
static UserModel? getUser() {
  return UserModel.fromJson(
    jsonDecode(
      _sharedPreferences.getString(
        AppStrings.kCachedUser,
      )!,
    ),
  );
}


---

# 8. Cache Safety Rules

All cache operations MUST be wrapped with:

dart
try/catch


---

## Example

dart
try {
  return sl<SharedPreferences>().getString(key);
} catch (e) {
  return null;
}


---

# 9. SharedPreferences Access Rule

SharedPreferences instance should be centralized:

dart
final SharedPreferences _sharedPreferences =
    sl<SharedPreferences>();


---

## Forbidden

❌ Creating multiple SharedPreferences instances
❌ Injecting SharedPreferences into UI

---

# 10. Cache Usage Inside Cubit

Cubit may:

* preload cached data
* fallback to cache
* sync realtime updates into cache

---

## Example

dart
_people ??= CacheManager.getPeople();


---

# 11. Realtime + Cache Sync Pattern

When using Firebase streams:

1. Load cached data first
2. Emit loading/success state
3. Listen to realtime updates
4. Update cache continuously

---

## Example

dart
_people ??= CacheManager.getPeople();

_peopleSub = FirebaseService.watchCollection(
  collectionName: FirebaseCollections.people,
).listen(
  (snap) {
    _people
      ?..clear()
      ..addEntries(
        snap.docs.map((doc) {
          final model = PersonModel.fromJson(doc.data());
          return MapEntry(model.id, model);
        }),
      );

    CacheManager.setPeople(_people!);

    emit(
      GetPeopleState(
        status: RequestStatus.success,
      ),
    );
  },
);


---

# 12. Cache Nullable Rule

Cached collections should usually be nullable:

dart
Map<String, PersonModel>? _people;


Because:

* null = not loaded yet
* empty = loaded but empty

This distinction is IMPORTANT.

---

# 13. Getter Exposure Rule

Private cache variables MUST be exposed using getters only.

---

## Example

dart
Map<String, PersonModel> get people {
  return searchController?.text.trim().isNotEmpty == true
      ? _filteredPeople ?? {}
      : _people ?? {};
}


---

# 14. Filtering Rule

Filtering must happen on cached in-memory data.

NOT by:

* refetching API
* refetching Firebase
* querying storage repeatedly

---

## Correct

dart
_filteredPeople = Map.fromEntries(
  _people!.entries.where(
    (entry) =>
        entry.value.name.toLowerCase().contains(query),
  ),
);


---

# 15. Clear Cache Rules

Global cache clearing belongs ONLY to:

dart
UserSessionService.emptyCache()


---

## Forbidden

❌ Random cache clearing inside features
❌ Clearing unrelated feature cache

---

# 16. Feature Cache Rules

Each feature may define:

dart
setProducts()
getProducts()

setPeople()
getPeople()

setOrders()
getOrders()


inside CacheManager.

---

# 17. Cache Naming Rules

All cache keys MUST be centralized inside:

dart
AppStrings


---

## Forbidden

❌ Hardcoded cache keys

---

# 18. Offline-First Philosophy

Features should prefer:

txt
Cache First
 → Realtime/API Sync Second


This ensures:

* faster UI
* smoother UX
* reduced loading
* offline support

---

# 19. Memory vs Persistent Cache

## Memory Cache

Inside Cubit:

dart
List<ProductModel>? products;


Temporary runtime cache.

---

## Persistent Cache

Inside SharedPreferences via CacheManager.

Survives app restart.

---

# 20. Cache Lifecycle Rules

Cubit should:

* initialize cache loading inside initFeature()
* clear temporary memory inside disposeFeature()

BUT:

Persistent cache remains until:

* logout
* explicit removal
* cache expiration logic

---

# 21. Cache + State Relationship

Cached data MAY still represent success state.

Example:

dart
final isSuccess =
    state is GetPeopleState &&
        state.status == RequestStatus.success ||
    cubit.people.isNotEmpty;


Because cached data is valid renderable data.

---

# 22. Dependency Injection Rules

Allowed ONLY inside:

* CacheHelper
* CacheManager
* Services
* Cubits

---

## Forbidden

❌ sl() inside UI

---

# 23. Architecture Goal

This architecture ensures:

* centralized cache management
* reusable storage system
* offline-ready architecture
* scalable feature caching
* predictable cache flow
* consistent data lifecycle
* AI-friendly architecture



