# Repository and Data Source Architecture Rules

Repository and data-source layers are required for features that may use a
remote API, Supabase, local cache, or a local database.

## Layer Flow

```text
UI
  ↓
Cubit
  ↓
Repository
  ↓
RemoteDataSource / LocalDataSource
  ↓
ApiServices / Supabase / CacheManager / local database
```

## Data Sources

- Remote data sources own remote client calls and response parsing.
- Local data sources own cache and local database reads/writes.
- Data sources must not emit Cubit states, navigate, show toasts, or access UI.
- Supabase access must remain inside a remote data source.

## Repositories

- Repositories coordinate remote and local data sources.
- Repositories expose models and response models to Cubits.
- Repositories decide cache-first, refresh, fallback, and synchronization flow.
- Repositories must not access widgets, emit states, navigate, or show toasts.

## Cubit Rules

- Cubits call repositories, not ApiServices, Supabase, SharedPreferences, or
  database clients directly.
- Cubits own in-memory state, pagination, search, filtering, and controllers.
- Paginated repository methods return response models implementing
  `PaginatedResponse` and containing `PaginationModel`.

## Feature Structure

```text
lib/view/{feature}/data/
├── datasource/
│   ├── {feature}_remote_data_source.dart
│   └── {feature}_local_data_source.dart
├── repository/
│   ├── {feature}_repository.dart
│   └── {feature}_repository_impl.dart
└── models/
```

## Naming

- `{feature}_remote_data_source.dart`
- `{feature}_local_data_source.dart`
- `{feature}_repository.dart`
- `{feature}_repository_impl.dart`
- `{feature}_response_model.dart`
