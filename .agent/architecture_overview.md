# Project Architecture Rules

## Overview

The project follows a strict feature-based architecture with clear separation between:

- `core/` → shared infrastructure and reusable app-wide logic
- `model/` → shared data models and entities
- `view/` → feature-based UI, Cubits, pages, and widgets

Each file must belong to its correct layer. No mixing between layers is allowed.

---

# Root Structure

txt
lib/
├── core/
├── model/
├── view/
├── firebase_options.dart
└── main.dart


---

# 1. Core Layer

The `core/` folder contains shared infrastructure used across the entire application.

Nothing inside `core/` should belong to a single feature.

txt
core/
├── components/
├── constants/
├── errors/
├── services/
└── theme/


---

## 1.1 Core Components

Reusable UI widgets across multiple features.

txt
components/
├── buttons/
├── text_fields/
├── dialogs/
├── loading/
├── appbars/
├── cards/
└── ...


### Rules

- Must be reusable across features
- Must be generic
- Must not contain feature-specific logic
- If a widget becomes feature-specific, move it to its feature folder

---

## 1.2 Constants

txt
constants/
├── extensions/
├── enums/
├── strings/
├── api/
├── firebase/
└── app_constants.dart


### Rules

- All constants must be centralized
- No raw strings anywhere in code
- No duplicated constants

---

### Extensions

txt
extensions/
├── double_ex.dart
├── string_ex.dart
├── context_ex.dart
└── ...


---

### Enums

txt
enums/
├── login_options_enum.dart
├── user_role_enum.dart
├── request_status_enum.dart
└── ...


---

### Strings

txt
strings/
├── app_strings.dart
├── firestore_strings.dart
├── validation_strings.dart
└── ...


---

### API Endpoints

txt
api/
└── api_endpoints.dart


### Rules

- All endpoints must be centralized
- No hardcoded URLs anywhere in the project

---

### Firebase Collections

txt
firebase/
└── firebase_collections.dart


### Rules

- All collection names must be centralized
- No raw Firestore collection names anywhere

---

### App Constants

txt
app_constants.dart


Contains:

- App configuration
- Support numbers
- Global fixed values

---

## 1.3 Errors

txt
errors/
└── error_handler.dart


### Rules

- Centralized error transformation
- Converts exceptions into user-friendly messages
- Shared across the entire application

---

## 1.4 Services

txt
services/
├── api_services.dart
├── firebase_service.dart
├── dependency_injection.dart
├── logging_service.dart
├── notification_service.dart
├── permission_service.dart
├── location_service.dart
├── base/
└── ...


### Rules

- Shared logic across multiple features
- Encapsulate external integrations
- Must not depend on UI layer
- Must remain feature-independent

---

## 1.5 Base Services

The `base/` folder contains reusable infrastructure shared across the project.

txt
services/
└── base/
    ├── asset_service.dart
    ├── data_state_helper.dart
    ├── debouncer.dart
    ├── request_helper.dart
    ├── safe_executer.dart
    ├── scroll_manager.dart
    ├── search_manager.dart
    ├── system_ui_service.dart
    └── ...


### Rules

The `base/` folder contains reusable architecture utilities only.

Examples:

- request lifecycle helpers
- pagination helpers
- data state helpers
- scroll managers
- search managers
- debouncers
- async execution helpers
- shared utility services

### Forbidden

❌ Feature-specific business logic

❌ Feature-specific models

❌ Feature-specific API/Firebase implementation

❌ UI code

❌ Feature-dependent services

Everything inside `core/services/base` must remain generic and reusable across the application.

---

## 1.6 Theme

txt
theme/
├── app_theme.dart
├── app_colors.dart
├── app_dimens.dart
├── app_text_styles.dart
└── ...


### Rules

- No hardcoded colors
- No hardcoded spacing
- No inline text styles

---

# 2. Views Layer

The `views/` folder contains all application features.

Each feature is fully isolated.

txt
views/
├── auth/
├── home/
├── invoices/
└── ...


---

# Feature Structure

txt
views/{feature}/
├── controller/
├── pages/
└── widgets/


---

## 2.1 Controller

txt
controller/
├── login_cubit/
│   ├── login_cubit.dart
│   └── login_states.dart
└── register_cubit/
    ├── register_cubit.dart
    └── register_states.dart


### Rules

* Business logic only
* API/Firebase communication only
* Holds feature state
* Holds controllers, focus nodes and form keys
* Holds feature variables
* Coordinates feature flow
* Uses only centralized helpers/services
* No UI code allowed

---

## 2.2 Pages

txt
pages/
├── login_page.dart
├── register_page.dart
└── ...


### Rules

* UI composition only
* Calls Cubit methods only
* No business logic
* No state variables
* No API/Firebase calls
* No helper methods
* No widget builder methods
* Only init/dispose lifecycle logic

---

## 2.3 Widgets

Widgets are grouped by page.

txt
widgets/
├── login/
│   ├── login_form_widget.dart
│   ├── login_header_widget.dart
│   └── ...
├── register/
│   └── register_form_widget.dart
└── shared/
    └── auth_background_widget.dart


### Rules

* Page-specific widgets remain inside feature
* Shared feature widgets go to `shared/`
* Move to `core/components` only when reused across multiple features
* Widgets must remain purely visual
* No business logic
* No Cubit creation
* No service calls

---

# 3. Layer Communication

The application follows one-way communication only.

txt
UI
 ↓
Cubit
 ↓
RequestHelper / FirebaseHelper
 ↓
ApiServices / FirebaseServices
 ↓
Server / Firebase


Responses flow back through the same path.

txt
Server / Firebase
 ↓
ApiServices / FirebaseServices
 ↓
RequestHelper / FirebaseHelper
 ↓
Cubit
 ↓
State
 ↓
UI


No layer may skip another layer.

---

# Architecture Principles

The system enforces:

* strict layer separation
* feature isolation
* centralized request handling
* centralized Firebase handling
* reusable shared infrastructure
* predictable folder structure
* scalable architecture
* low coupling
* high readability
* AI-friendly code generation

---

# AI Development Rules

The AI must always:

* place files in their correct layer
* follow the existing project architecture only
* never introduce alternative architectures
* reuse existing helpers before creating new ones
* keep business logic inside Cubits
* keep UI purely compositional
* use RequestHelper for API requests
* use FirebaseHelper for Firebase operations
* use Base Models for request/response wrappers
* avoid duplicated variables (never create both public/private versions unless required)
* avoid unnecessary abstractions
* keep architecture consistent across all features