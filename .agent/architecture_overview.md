# Project Architecture Rules

## 1. Overview

The project follows a **Feature-Based Architecture** inspired by Clean Architecture principles.

### Core Principles

- Strict separation of responsibilities.
- Feature isolation.
- Reusable shared infrastructure.
- Centralized network, caching, and error handling.
- Repository and DataSource separation.
- Cubit-based state management.
- Clean, maintainable, and scalable code.
- Avoid unnecessary abstractions and overengineering.

---

## 2. Project Structure

```text
lib/
├── core/
│   ├── constants/
│   │   ├── base/
│   │   └── domain/
│   ├── enums/
│   │   ├── base/
│   │   └── domain/
│   ├── extensions/
│   │   ├── base/
│   │   └── domain/
│   ├── errors/
│   ├── localization/
│   ├── network/
│   │   └── cache/
│   ├── routes/
│   ├── security/
│   ├── services/
│   │   ├── base/
│   │   └── domain/
│   ├── theme/
│   ├── utils/
│   └── widgets/
│       ├── buttons/
│       ├── text_fields/
│       ├── dialogs/
│       ├── loading/
│       ├── lists/
│       ├── grids/
│       ├── shimmer/
│       ├── appbars/
│       └── cards/
│
├── model/
│   ├── base/
│   └── domain/
│
├── view/
│   └── {feature}/
│       ├── data/
│       │   ├── datasource/
│       │   ├── repository/
│       │   └── models/
│       └── ui/
│           ├── controllers/
│           │   └── {feature}_cubit/
│           │       ├── {feature}_cubit.dart
│           │       └── {feature}_states.dart
│           ├── pages/
│           └── widgets/
│               ├── {page_name}/
│               └── shared/
│
├── firebase_options.dart
└── main.dart
```

Create directories only when needed. Do not generate empty architectural layers.

---

## 3. Core Layer

The `core/` directory contains shared infrastructure and reusable application-wide functionality.

### 3.1 Base vs Domain

Applies to:

- Constants
- Enums
- Extensions
- Services
- Shared Models

**Base**

Generic, reusable functionality that is independent of the application's business domain.

Examples:
- RequestStatus
- Generic extensions
- RequestHelper
- Pagination utilities
- Base response models

**Domain**

Application-wide functionality related to the application's business domain.

Examples:
- Shared business enums
- Application-specific constants
- Shared domain extensions
- Shared domain services
- Shared business models

Rules:

- Feature-specific code must remain inside its feature.
- `domain/` under `core/` or `model/` does not represent a mandatory Clean Architecture Domain Layer.
- Do not move code to Core simply to avoid duplication inside one feature.

### 3.2 Core Widgets

Located in:

`core/widgets/`

Rules:

- Must be reusable across features.
- Must not contain feature-specific business logic.
- Prefer existing shared widgets before creating new ones.
- Avoid unnecessary wrapper widgets.
- Extend shared widgets only when the new behavior is broadly reusable.
- Feature-specific presentation belongs inside the feature.

### 3.3 Constants

Located in:

`core/constants/`

Responsibilities:

- Application constants.
- Shared configuration values.
- API endpoints.
- Firebase collection names.
- Shared static strings.

Rules:

- Centralize shared and repeated constants.
- Never hardcode API base URLs or endpoints throughout features.
- Never duplicate Firebase collection names.
- Context-specific literals are allowed when extraction provides no benefit.

### 3.4 Enums & Extensions

Located in:

`core/enums/`

`core/extensions/`

Rules:

- Generic reusable enums/extensions belong in `base/`.
- Shared application-domain enums/extensions belong in `domain/`.
- Feature-specific enums/extensions remain inside their feature.
- Avoid creating unnecessary extensions for trivial operations.

### 3.5 Errors

Located in:

`core/errors/`

Responsibilities:

- Centralized error transformation.
- Shared exception handling.
- User-friendly error messages.
- Reusable error contracts.

### 3.6 Network & Cache

Located in:

`core/network/`

Responsibilities:

- Shared networking infrastructure.
- HTTP client configuration.
- Interceptors.
- Session and token handling.
- Shared cache infrastructure.

Rules:

- UI must never execute HTTP requests directly.
- UI must never access local storage directly.
- Backend access must remain centralized.
- Feature-specific fetching, caching, and synchronization policies belong in the Repository.
- Shared cache utilities remain reusable and feature-independent.

### 3.7 Services

Located in:

`core/services/`

Responsibilities:

- Shared application services.
- Backend infrastructure.
- Dependency injection.
- Logging.
- Notifications.
- Permissions.
- Location.
- Shared lifecycle utilities.

Examples of reusable base services:

- RequestHelper
- DataStateHelper
- Debouncer
- SafeExecuter
- ScrollManager
- SearchManager
- PaginationManager
- AssetService
- SystemUIService

Rules:

- Services must not depend on the UI layer.
- Base services must remain generic.
- Feature-specific services belong inside their feature.
- Do not store feature UI state inside shared services.
- Avoid duplicating existing helper functionality.

### 3.8 Theme

Located in:

`core/theme/`

Responsibilities:

- Application themes.
- Shared colors.
- Typography.
- Spacing.
- Dimensions.
- Shared visual styles.

Rules:

- Prefer centralized design tokens.
- Avoid repeated hardcoded colors and dimensions.
- Prefer theme-based text styles.
- Local styling is allowed when intentionally feature-specific.
- Shared theme changes must not unintentionally affect unrelated features.

### 3.9 Additional Core Directories

- `localization/`: App-wide localization infrastructure.
- `routes/`: Centralized navigation configuration.
- `security/`: Shared security utilities.
- `utils/`: Generic utilities that do not fit a more specific layer.

Do not use `utils/` as a dumping ground for unrelated logic.

---

## 4. Models Architecture

### 4.1 Shared Models

Located in:

`lib/model/`

Structure:

```text
model/
├── base/
└── domain/
```

**Base Models**

Generic contracts and reusable data structures.

Examples:

- PaginationModel
- BaseResponseModel
- BaseRequestModel

**Domain Models**

Business models genuinely shared between multiple features.

### 4.2 Feature Models

Located in:

`view/{feature}/data/models/`

Rules:

- Feature-specific models must remain inside their feature.
- Models should own serialization and data representation.
- Avoid storing unrelated feature models in the global `model/` directory.
- Move a model to shared `model/domain/` only when it represents a genuinely shared concept.
- Avoid direct dependencies between unrelated features.

### 4.3 Optional Domain Layer

A dedicated Clean Architecture Domain Layer may be introduced when justified by complexity.

Examples:

- Complex business entities.
- Independent business use cases.
- Multiple interchangeable data implementations.

Do not create separate Entities, UseCases, or Mappers automatically for every simple feature.

---

## 5. Feature Architecture

Every feature is organized into two main sections:

- `data/`
- `ui/`

### 5.1 Data Layer

```text
data/
├── datasource/
├── repository/
└── models/
```

**DataSource Responsibilities**

- Communicate with remote APIs or Firebase.
- Access local databases or local storage through shared infrastructure.
- Handle data-source-specific operations.
- Convert raw external data when appropriate.
- Remain independent of UI and Cubit states.

**Repository Responsibilities**

- Coordinate DataSources.
- Expose feature data to Cubits.
- Decide cache-first or remote-first strategies.
- Handle refresh and fallback behavior.
- Coordinate synchronization.
- Keep data access independent of UI.

Rules:

- Cubits must not directly access ApiServices, Firebase clients, or database clients for feature data.
- Repositories must not emit Cubit states.
- DataSources must not navigate or display UI messages.
- Avoid unnecessary repository wrappers that provide no architectural value.

### 5.2 UI Layer

```text
ui/
├── controllers/
├── pages/
└── widgets/
```

**Controllers / Cubits**

Responsibilities:

- Feature state ownership.
- Business logic.
- Validation.
- Search and filtering.
- Sorting.
- Pagination state.
- Form controllers and focus nodes when needed.
- Request orchestration through Repositories.
- State emission.
- Feature initialization and disposal.

Rules:

- Never place rendering logic inside Cubits.
- Never execute raw HTTP/Firebase queries directly.
- Reuse existing lifecycle and request helpers where applicable.

**Pages**

Responsibilities:

- Compose the screen.
- Connect UI components.
- Provide Cubit dependencies at appropriate feature boundaries.
- Delegate user actions to Cubits.

Rules:

- No business logic.
- No direct API/Firebase calls.
- No response parsing.
- No feature-data transformations inside `build()`.
- Simple presentation helpers are allowed.
- Keep pages focused on composition.

**Widgets**

Responsibilities:

- Render UI.
- Receive required data.
- Delegate actions.
- Rebuild only when needed.

Rules:

- Prefer StatelessWidget.
- Use StatefulWidget when local UI state or lifecycle ownership is necessary.
- Keep widgets focused on a single visual responsibility.
- Feature widgets remain inside their feature.
- Shared feature widgets belong in `ui/widgets/shared/`.

### 5.3 Widget Class Rules

- One independent Widget class per file.
- Do not extract UI sections into functions returning `Widget`.
- Extract reusable or complex UI sections into StatelessWidget or StatefulWidget classes.
- StatefulWidget and its associated State class are allowed in the same file.
- Normal Flutter builder callbacks, such as `itemBuilder`, are allowed.
- Avoid unnecessary splitting of trivial UI elements.

Detailed rules belong in `ui_architecture_rules.md`.

---

## 6. Layer Communication

### Standard Data Flow

```text
UI (Page / Widget)
       |
       v
     Cubit
       |
       v
   Repository
       |
       v
   DataSource
       |
       v
Core Infrastructure
(ApiServices / FirebaseService /
 CacheManager / Local Database)
       |
       v
Backend / Local Storage
```

### Response Flow

```text
Backend / Local Storage
       |
       v
Core Infrastructure
       |
       v
   DataSource
       |
       v
   Repository
       |
       v
     Cubit
       |
       v
     State
       |
       v
      UI
```

Rules:

- Preserve separation between UI, business logic, and data access.
- Use Repository and DataSource for feature persistence and remote access.
- Shared RequestHelper functionality may be used within the appropriate data-access implementation.
- Purely local UI interactions do not require Repository or DataSource.
- Do not create artificial layers for operations that do not require them.

---

## 7. Architecture Principles

The application must follow:

1. Single Responsibility Principle.
2. Separation of Concerns.
3. Feature Isolation.
4. Low Coupling.
5. High Cohesion.
6. Centralized Shared Infrastructure.
7. Predictable Folder Structure.
8. Reusable Components.
9. Minimal Duplication.
10. Maintainability and Scalability.
11. Consistent State Management.
12. Avoid Overengineering.

---

## 8. AI Development Rules

AI coding agents must:

1. Inspect existing code before introducing new implementations.
2. Follow the project's established folder structure.
3. Read only the architecture rules relevant to the current task.
4. Place feature-specific code inside its owning feature.
5. Reuse existing helpers, services, and widgets.
6. Keep business logic outside UI components.
7. Keep remote and persistent data access behind Repositories and DataSources.
8. Prefer feature-local models over global models.
9. Avoid unnecessary abstractions, wrappers, and duplicate variables.
10. Prefer small, focused Widget classes over large build methods.
11. Preserve existing behavior during architectural refactoring.
12. Avoid introducing alternative architectural patterns without explicit approval.
13. Follow the specialized rules for Cubits, Models, UI, API, Firebase, Cache, and Code Quality.
14. Create only the directories and layers required by the actual feature.
15. Prefer consistency and readability over theoretical architectural complexity.

---

## 9. Final Architecture Philosophy

> Keep features self-contained, infrastructure reusable, data access isolated, and UI purely presentational.

The architecture should remain scalable without introducing complexity that provides no practical value.