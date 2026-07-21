# Flutter Base Project

A scalable, modular Flutter base project with strict architecture rules, AI-friendly code generation, and centralized infrastructure.

---

## Architecture Overview

The project follows a **feature-based architecture** with strict separation between layers:

```
lib/
├── core/       → shared infrastructure and reusable app-wide logic
├── model/      → shared data models and entities
├── view/       → feature-based UI, Cubits, pages, and widgets
├── firebase_options.dart
└── main.dart
```

No mixing between layers is allowed. Each file must belong to its correct layer.

---

## Core Layer

The `core/` folder contains shared infrastructure used across the entire application.

```
core/
├── components/      → reusable UI widgets (buttons, text fields, dialogs, loading, appbars, cards)
├── constants/       → extensions, enums, strings, API endpoints, Firebase collections, app constants
├── errors/          → centralized error_handler.dart
├── services/        → api_services, firebase_service, dependency_injection, logging, notification, permissions, location
│   └── base/        → reusable architecture utilities (request helpers, pagination, scroll/search managers, debouncers)
└── theme/           → app_theme, app_colors, app_dimens, app_text_styles
```

### Core Components

Reusable widgets that must be used across features:

| Component | File | Purpose |
|-----------|------|---------|
| Scroll Widgets | `custom_listview_widget.dart` | Lists, grids, pagination, shimmer |
| Image Widget | `my_image.dart` | All image rendering (asset, network, svg, memory, file) |
| Adaptive Dialog | `adaptive_dialog_widget.dart` | Platform-adaptive dialogs |
| Bottom Sheet | `bottom_sheet_widget.dart` | Standardized bottom sheets |
| Toast | `show_toast.dart` | Lightweight user feedback |
| Buttons | `btn_widget.dart` | `BtnWidget`, `CustomBtnWidget`, `TextBtnWidget`, `IconBtnWidget` |
| Dropdown | `drop_down_btn_widget.dart` | `DropDownBtnWidget<T>` |
| Text Field | `text_field_widget.dart` | `TxtFieldWidget` |
| Search Field | `search_txt_field_widget.dart` | `SearchTextFieldWidget` |
| Pin Code | `pin_code_txt_field_widget.dart` | `PinCodeTxtFieldWidget` |
| Data State Builder | `data_state_builder_widget.dart` | Async data rendering (loading/success/empty/error) |
| Empty View | `empty_view_widget.dart` | Empty data screens |
| Error View | `error_view_widget.dart` | Failure screens with retry |
| Loading View | `loading_view_widget.dart` | Loading indicators |
| Shimmer Item | `shimmer_item_widget.dart` | Shimmer placeholders |
| App Scaffold | `custom_scaffold.dart` | Default page scaffold |

---

## Views Layer

Each feature is fully isolated:

```
views/{feature}/
├── controller/     → Cubit + States (business logic only)
├── pages/          → UI composition only
└── widgets/        → page-specific widgets, shared/ for feature-shared widgets
```

### Feature Rules

- **Controller**: Business logic only, API/Firebase communication, state management, controllers, form keys, focus nodes
- **Pages**: UI composition only, calls Cubit methods, no business logic
- **Widgets**: Purely visual, no business logic, no Cubit creation

---

## Layer Communication

```
UI → Cubit → RequestHelper / FirebaseHelper → ApiServices / FirebaseServices → Server / Firebase
```

Responses flow back through the same path. No layer may skip another layer.

---

## Key Architecture Rules

### Cubit & State Management

- Cubit owns all feature state (models, controllers, pagination, search, validation)
- State communicates Cubit changes (status, message, callbacks)
- Two state categories: **UI State** (rebuilding) and **Action State** (create/update/delete with `handleActionState()`)
- `RequestStatus` enum: `loading`, `success`, `failure`
- Single source of truth: Cubit is the only owner of feature data

### API Layer

- `ApiServices` is the ONLY gateway for HTTP communication
- All requests go through `RequestHelper.execute()` / `RequestHelper.executeAction()`
- Headers, tokens, session management are centralized in `ApiServices` and `UserSessionService`
- Session validation happens automatically inside `ApiServices`
- No direct HTTP/Dio usage in Cubits or UI

### Firebase Architecture

- `FirebaseService` is the centralized Firebase access layer
- Cubit decides fetch strategy (one-time vs realtime)
- Collection names centralized in `FirebaseCollections`
- Document IDs stored inside model data itself
- FirebaseService remains stateless

### Cache & Local Storage

- `CacheHelper` → low-level SharedPreferences wrapper
- `CacheManager` → high-level app cache layer (caching models)
- Flow: UI → Cubit → CacheManager → CacheHelper → SharedPreferences
- Offline-first philosophy: Cache first, then API/Firebase sync
- Cached data persists until logout or explicit removal

### Models & Classes

Six types of classes:

| Type | Purpose | Naming |
|------|---------|--------|
| Data Model | Backend data (API/Firebase/cache) | `*_model.dart` |
| Response Model | API response wrappers | `*_response_model.dart` |
| UI Entity | UI-only data representation | `*_entity.dart` |
| Plain Class | Services, helpers, managers | No suffix required |
| Base Contract | Shared response interfaces | Abstract classes |
| Base State | Shared request behavior | Abstract state classes |

All Data Models use Playx parsing helpers (`asStringOr`, `asIntOr`, `asMapOr`, `asListOr`, etc.) and extend `Equatable`.

### Code Quality

- No redundant default parameters
- `snake_case.dart` file naming
- Pages end with `_page.dart`, widgets with `_widget.dart`, cubits with `_cubit.dart`, states with `_states.dart`, models with `_model.dart`
- One class per file
- No unnecessary local variables
- No empty lines between logically related code
- Const constructors preferred

---

## AI Instructions

This project includes comprehensive AI instructions in the `Agent/` folder. These rules ensure consistent, predictable code generation.

### Architecture Index

| Rule File | Description |
|-----------|-------------|
| `architecture_overview.md` | Overall system design and layer structure |
| `architecture_index.md` | Entry point for all architecture rules |
| `cubit_states_architecture.md` | Cubit and state management system |
| `api_layer_and_services_rules.md` | API layer, networking, and session handling |
| `firebase_architecure_rules.md` | Firebase usage and Firestore patterns |
| `cache_and_local_storage_rules.md` | Caching and local storage architecture |
| `ui_architecture_rules.md` | UI composition and rendering rules |
| `models_entities_classes_rules.md` | Models, entities, and class types |
| `code_quality_rules.md` | Naming conventions and code cleanliness |
| `core_widgets_rules.md` | Core widget usage rules |
| `github_commits.md` | Conventional Commits specification |
| `token-efficiency/SKILL.md` | Token efficiency guidelines |

### Key AI Rules

1. **Always start with `architecture_index.md`** — it is the single source of truth
2. **Place files in correct layer** — never mix core/model/view
3. **Reuse existing helpers** before creating new ones
4. **Business logic stays in Cubits** — UI is purely compositional
5. **Use RequestHelper for API** — use FirebaseHelper for Firebase
6. **Use Base Models** for request/response wrappers
7. **Never introduce alternative architectures**
8. **Keep architecture consistent** across all features

---

## Git Conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `build`

---

## Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Follow the architecture rules in `Agent/architecture_index.md`
4. Start building features in `lib/view/{feature}/`

---

## License

This project is a base template for Flutter applications.
