# Repository & DataSource Architecture Rules

## 1. Core Principle

The application follows a Repository + DataSource architecture.

Supported data sources:

- REST API through `backend_sdk`
- Supabase through `backend_sdk`
- Local Cache through `CacheManager` and `CacheHelper`

Firebase support will be added later.

**Only create the DataSource implementations explicitly required by the feature.**

All feature data access must go through repositories.

---

## 2. Architecture Flow

```text
UI
 ↓
Cubit
 ↓
Repository (Abstract / Implementation)
 ↓
Required DataSource Contracts
 ├── API Implementation        → backend_sdk       [Optional]
 ├── Supabase Implementation   → backend_sdk       [Optional]
 └── Cache Implementation      → CacheManager      [Optional]
```

- Implementations are selected according to feature requirements.
- Never create unused providers, contracts, or implementations.
- A feature may use one or multiple data sources.
- Repositories expose models or typed results to Cubits.

---

## 3. Feature Structure

```text
view/{feature}/
├── data/
│   ├── datasource/
│   │   ├── {feature}_remote_data_source.dart
│   │   ├── {feature}_api_data_source.dart
│   │   ├── {feature}_supabase_data_source.dart
│   │   ├── {feature}_local_data_source.dart
│   │   └── {feature}_cache_data_source.dart
│   ├── repository/
│   │   ├── {feature}_repository.dart
│   │   └── {feature}_repository_impl.dart
│   └── models/
└── ui/
    └── controllers/
```

**This structure illustrates available options, not mandatory files.**

Only create the files needed by the feature.

---

## 4. DataSource Contracts

- Every DataSource contract MUST be an abstract class or abstract interface class.
- Each contract MUST have its own separate file.
- Every concrete implementation MUST have its own file.
- Multiple implementations MAY share one contract when they expose equivalent operations.
- Remote and Local DataSources SHOULD use separate contracts when their responsibilities differ.
- Do not create an abstract contract for an unused data source.
- Never combine multiple provider implementations in one class.
- Use dependency injection to select implementations.
- DataSources MUST NOT depend on UI or Cubit states.

### Example: API Only

```text
datasource/
├── products_remote_data_source.dart
└── products_api_data_source.dart
```

### Example: Supabase Only

```text
datasource/
├── products_remote_data_source.dart
└── products_supabase_data_source.dart
```

### Example: API + Cache

```text
datasource/
├── products_remote_data_source.dart
├── products_api_data_source.dart
├── products_local_data_source.dart
└── products_cache_data_source.dart
```

### Example: API + Supabase

```text
datasource/
├── products_remote_data_source.dart
├── products_api_data_source.dart
└── products_supabase_data_source.dart
```

Both remote implementations may share:

```dart
abstract interface class ProductsRemoteDataSource {
  Future<ProductModel> getProduct(String id);
}
```

Local cache may use a separate contract:

```dart
abstract interface class ProductsLocalDataSource {
  Future<ProductModel?> getCachedProduct(String id);
  Future<void> saveProduct(ProductModel product);
}
```

Never force remote and local operations into the same interface when their responsibilities differ.

---

## 5. REST API DataSource

- Use `ApiClient` from `backend_sdk`.
- Use centralized API endpoints.
- Reuse SDK request, response, error, and pagination types where applicable.
- Do not create custom HTTP clients inside features.
- Do not duplicate networking functionality provided by the SDK.
- Keep API-specific request parameters and response mapping inside the DataSource.
- Create an API implementation only when required.

---

## 6. Supabase DataSource

- Use the typed clients provided by `backend_sdk`.
- Keep Supabase-specific queries inside the DataSource.
- Reuse SDK models, pagination, filters, and result types.
- Do not access Supabase directly from Cubits or Repositories.
- Do not duplicate SDK functionality.
- Create a Supabase implementation only when required.

---

## 7. Local Cache DataSource

Current implementation:

```text
core/network/cache/
├── cache_manager.dart
├── cache_helper.dart
└── cache_keys.dart
```

Rules:

- Create a Local DataSource only when the feature requires persistent local data.
- Local DataSources MUST use the existing `CacheManager` and `CacheHelper`.
- `CacheHelper` handles primitive storage operations.
- `CacheManager` handles application-specific cached models and data.
- Do not access SharedPreferences directly inside feature DataSources.
- Keep JSON serialization and deserialization outside UI and Cubits.
- Keep cache keys centralized.
- Keep cache operations isolated from remote implementations.

### Future SDK Migration

`CacheManager` and `CacheHelper` are planned to move into `backend_sdk`.

Until that implementation is available:

- Continue using the existing Core Cache implementation.
- Do not assume or invent SDK Cache APIs.
- Keep local DataSource contracts independent of the storage implementation.
- Prefer consistent typed model contracts across remote and local sources.
- Reuse SDK generic models where applicable.
- The migration should not require changes to Cubits or repository contracts.

---

## 8. Repository Rules

Each feature repository must have:

- An abstract repository contract.
- A separate repository implementation.

Responsibilities:

- Coordinate only the DataSources required by the feature.
- Decide cache-first or remote-first strategies when caching is enabled.
- Handle refresh, fallback, and synchronization when applicable.
- Return models or consistent typed results.
- Keep backend implementation details hidden from Cubits.

Forbidden:

- Direct HTTP requests.
- Direct Supabase queries.
- Direct SharedPreferences access.
- UI navigation or state emission.
- Duplicate caching or networking implementations.

A repository may depend on one or multiple DataSources depending on requirements.

---

## 9. Cubit Rules

Cubits MUST:

- Depend on Repository contracts.
- Own feature state and in-memory data.
- Handle search, filtering, sorting, and UI pagination.
- Use existing request lifecycle helpers when applicable.

Cubits MUST NOT:

- Access API or Supabase clients directly.
- Access CacheManager or CacheHelper for feature data persistence.
- Execute raw database queries.
- Know which backend implementation is being used.

---

## 10. Models & Response Rules

- Feature-specific models belong in `data/models/`.
- Shared models belong in `model/base/` or `model/domain/`.
- Reuse generic models and contracts provided by `backend_sdk`.
- Avoid duplicating SDK response, pagination, and error models.
- DataSources handle source-specific mapping.
- Repositories must expose consistent return contracts.
- API, Supabase, and Cache implementations should expose the same model type when representing the same data.
- Do not force incompatible response wrappers onto local cache operations.

---

## 11. Code Quality Rules

- One independent class per file.
- One responsibility per DataSource.
- Create only requested provider implementations.
- Do not mix provider implementations.
- Prefer constructor dependency injection.
- Depend on abstractions, not concrete implementations.
- Do not duplicate SDK functionality.
- Do not create unnecessary wrappers.
- Preserve clean separation between data access and business logic.

---

## 12. Future Firebase Support

Firebase is not part of the current implementation scope.

When introduced:

- Add a dedicated Firebase DataSource implementation only when required.
- Reuse existing repository and DataSource contracts where appropriate.
- Do not modify Cubits to accommodate Firebase.
- Follow separate Firebase architecture and cost optimization rules.