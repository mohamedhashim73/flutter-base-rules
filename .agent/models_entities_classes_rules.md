# Models, Entities & Classes Rules

## Overview

Not every class in the project is a Model.

There are **6 types of classes** in the architecture:

- Data Models
- Response Models
- UI Entities
- Plain Classes
- Base Contracts (Interfaces / Abstract Classes)
- Base State Classes

Each type has a specific responsibility and must follow its own rules.

---

# 1. Data Models

## Purpose

Data Models represent backend data.

They are used for:

- API responses
- Firebase documents
- Local cache
- Persistent data

Examples:

dart
UserModel
OrderModel
ProductModel
AddressModel


---

## Naming

File:

txt
*_model.dart


Class:

txt
SomethingModel


---

## Required Features

Every Data Model should contain:

- const constructor
- factory fromJson()
- toJson()
- copyWith()
- Equatable

---

## Serialization Rule

Every Data Model must be serializable.

Required methods:

dart
factory Model.fromJson(...)


dart
Map<String, dynamic> toJson()


---

## Parsing Rules

Always use the parsing helpers provided by Playx.

Preferred helpers:

dart
asStringOr(...)
asStringOrNull(...)
asIntOr(...)
asIntOrNull(...)
asDoubleOr(...)
asDoubleOrNull(...)
asBoolOr(...)
asBoolOrNull(...)
asMapOr(...)
asMapOrNull(...)
asListOr(...)
asLocalDateTimeOrNull(...)


Avoid manual parsing whenever a Playx helper exists.

---

## Forbidden Parsing

Do NOT write:

dart
json['id']


dart
json['items']


dart
json['address']


dart
DateTime.parse(...)


dart
int.parse(...)


Prefer:

dart
asIntOr(...)


dart
asMapOr(...)


dart
asListOr(...)


dart
asLocalDateTimeOrNull(...)


---

## Nested Model Rule

Nested models must use Playx parsing helpers.

Correct:

dart
address: AddressModel.fromJson(
  asMapOr(json, 'address'),
),


Nullable nested models:

dart
stock: asMapOrNull(json, 'stock') != null
    ? ProductStockModel.fromJson(
        asMapOr(json, 'stock'),
      )
    : null,


Never access nested json directly.

---

## List Parsing Rule

Collections must always use:

dart
asListOr(...)


Correct:

dart
items: asListOr(json, 'items')
    .map((e) => ItemModel.fromJson(e))
    .toList(),


Avoid:

dart
(json['items'] as List)


---

## Enum Rule

Enums should always be parsed through extension methods.

Correct:

dart
status: asStringOr(json, 'status').toOrderStatus,


Avoid manual enum mapping.

---

## Date Rule

Always use:

dart
asLocalDateTimeOrNull(...)


Never use:

dart
DateTime.parse(...)


unless absolutely required.

---

## Nullability Rules

Prefer Playx nullable parsing helpers whenever the backend field is optional.

Correct:

dart
couponId: asIntOrNull(json, 'coupon_id')


dart
createdAt: asLocalDateTimeOrNull(json, 'created_at')


dart
stock: asMapOrNull(json, 'stock') != null
    ? ProductStockModel.fromJson(
        asMapOr(json, 'stock'),
      )
    : null,


Avoid:

dart
json['coupon_id'] == null


dart
json['created_at'] != null
    ? DateTime.parse(...)
    : null


Always prefer the provided Playx parsing helpers.

---

## Collection Parsing Rules

Collections must always be parsed using Playx helpers.

Correct:

dart
items: asListOr(json, 'items')
    .map((e) => ItemModel.fromJson(e))
    .toList(),


Never cast manually:

dart
(json['items'] as List)


unless there is no helper available.

---

## Nested Object Rules

Nested objects must never access json directly.

Correct:

dart
address: AddressModel.fromJson(
    asMapOr(json, 'address'),
),


Nullable object:

dart
stock: asMapOrNull(json, 'stock') != null
    ? ProductStockModel.fromJson(
        asMapOr(json, 'stock'),
      )
    : null,


The same rule applies to every nested model.

---

## Playx Rule

This project relies on Playx utilities.

Models should prefer:

- Playx parsing helpers
- Playx Equatable

Avoid importing standalone packages when Playx already exposes them.

---

## copyWith Rule

Every mutable Data Model should expose:

dart
copyWith(...)


unless the model intentionally cannot be copied.

---

## Equatable Rule

Models should extend:

dart
Equatable


using Playx.

Do NOT import the Equatable package separately.

---

## Equality Rule

Prefer lightweight equality.

Usually:

dart
@override
List<Object?> get props => [id];


unless another identity is required.

---

# 2. UI Entities

## Purpose

Entities represent UI-only data.

They do NOT represent backend data.

Examples:

dart
HomeCardEntity
SettingsItemEntity
ProductImageItemEntity


---

## Naming

File:

txt
*_entity.dart


Class:

txt
SomethingEntity


---

## Rules

Entities:

- have no serialization
- have no fromJson
- have no toJson
- have no API knowledge
- have no Firebase knowledge
- have no cache knowledge

They only organize data for presentation.

---

## Allowed

Entities may:

- combine multiple models
- expose computed values
- simplify widget construction
- represent UI cards
- represent list items
- represent display objects

---

# 3. Plain Classes

## Definition

Plain Classes are neither Models nor Entities.

They are used for:

- services
- helpers
- managers
- configuration
- business utilities
- internal logic

Examples:

dart
LocationService
ValidationHelper
ThemeConfig
PaginationController
AuthManager


---

## Naming

No suffix is required.

Choose descriptive names.

---

## Rules

Plain Classes:

- do NOT require serialization
- do NOT require Equatable
- do NOT require copyWith
- may contain logic
- may contain methods
- may hold internal state

---

# 4. Decision Rules

Before creating any class, determine its responsibility.

## Backend Data

Use:

txt
Model


---

## UI Representation

Use:

txt
Entity


---

## Logic / Service / Helper

Use:

txt
Plain Class


---

# 5. Forbidden Mixing Rules

Never mix responsibilities.

Forbidden:

- Model with UI-only logic
- Entity with API parsing
- Entity with Firebase parsing
- Plain Class with serialization
- Service behaving as Model
- Helper exposing fromJson/toJson

Each class should have a single responsibility.

---

# 6. Folder Placement

Choose the folder based on responsibility.

Examples:

txt
models/


for backend data.

txt
entities/


for UI entities.

txt
services/


for services.

txt
helpers/


for helpers.

txt
configs/


for configuration classes.

Avoid mixing different class types in the same folder unless they belong to the same feature.

---

# 7. Final Philosophy

Before writing any class, always answer these questions:

1. Is this backend data?
2. Is this only for UI?
3. Is this a helper or service?
4. Does it require serialization?
5. Does it require Equatable?
6. Does it require copyWith?

Only after identifying its responsibility should the class be created.

---

# 8. Response Models

## Purpose

Response Models wrap API responses.

They are NOT business entities.

They organize:

- response data
- pagination
- metadata

Examples:

dart
OrdersResponseModel
ProductsResponseModel
CategoriesResponseModel


---

## Naming

File:

txt
*_response_model.dart


Class:

txt
SomethingResponseModel


---

## Responsibilities

Response Models should:

- parse API response envelopes
- expose parsed data
- expose pagination if available
- implement response contracts when needed

They should NOT contain business logic.

---

## Generic Response Contracts

Response Models should implement the appropriate base contract.

Single object response:

dart
implements LoadableResponse<UserModel>


Paginated response:

dart
implements PaginatedResponse<List<OrderModel>, OrdersResponseModel>


Do not create custom interfaces when one of the shared response contracts already fits the use case.

---

## Data Exposure Rule

Every Response Model exposes its parsed data through:

dart
data


Example:

dart
@override
final List<OrderModel> data;


or

dart
@override
OrderDetailsModel? get data => this;


This allows generic widgets and repositories to consume responses uniformly.

---

## Pagination Compatibility Rule

All paginated responses must remain compatible with the shared pagination engine.

Therefore every paginated response must implement:

dart
copyWithPagination(...)


without changing its signature.

---

## Required Interfaces

Single responses should implement:

dart
LoadableResponse<T>


Paginated responses should implement:

dart
PaginatedResponse<T, Self>


Example:

dart
class OrdersResponseModel
    implements
        PaginatedResponse<List<OrderModel>, OrdersResponseModel>


---

## Wrapper Rule

Response Models are wrappers.

Example:

json
{
  "data": {
    "data": [...],
    "pagination": {...}
  }
}


The wrapper is responsible for extracting:

- data
- pagination

and nothing more.

---

## Pagination Rule

Paginated responses must expose:

dart
pagination


using:

dart
PaginationModel


---

## copyWithPagination Rule

Every paginated response should expose:

dart
copyWithPagination(...)


This is required for reusable pagination logic.

Example:

dart
copyWithPagination({
    required List<dynamic> data,
    required PaginationModel? pagination,
})


---

## Parsing Rule

Response Models should also use Playx parsing helpers.

Correct:

dart
final response = asMapOr(
  json,
  'data',
  fallback: json,
);


Avoid direct json access whenever possible.

---

# 9. Base Response Contracts

## Purpose

Base contracts define the common architecture shared by response models.

They should only declare behavior.

They should never contain parsing logic.

---

## LoadableResponse

Represents any response containing data.

Example:

dart
abstract interface class LoadableResponse<T> {
  T? get data;
}


---

## PaginatedResponse

Represents paginated responses.

It extends:

dart
LoadableResponse


and additionally exposes:

- pagination
- copyWithPagination()

Example:

dart
abstract interface class PaginatedResponse<T, Self>


---

## Rules

Base contracts:

- should remain generic
- should not know concrete models
- should not contain business logic
- should only expose required APIs

---

## Interface Responsibility

Base contracts describe behavior only.

They should never:

- parse json
- contain business logic
- know feature models
- know API structure

They exist solely to define reusable contracts shared across the project.

---

# 10. Pagination Classes

## PaginationModel

Represents pagination metadata returned by the backend.

Example fields:

- total
- count
- perPage
- currentPage
- totalPages

---

## Rules

PaginationModel is considered a Data Model.

Therefore it should contain:

- fromJson
- toJson
- copyWith

It should use Playx parsing helpers.

---

## Computed Properties

PaginationModel may expose convenience getters.

Example:

dart
bool get hasNext =>
    currentPage < totalPages;


Computed values are encouraged when they improve readability.

---

## PaginationParams

Represents request parameters.

Example:

dart
PaginationParams(
    page: 2,
    perPage: 20,
)


---

## Rules

PaginationParams is NOT a Data Model.

It is a request helper.

It may contain:

- toMap()
- copyWith()

It does NOT require:

- fromJson
- Equatable
- serialization from backend

---

## PaginationModel Rules

PaginationModel is treated exactly like any other Data Model.

It should contain:

- const constructor
- fromJson
- toJson
- copyWith

It does not need additional response logic.

---

## PaginationParams Rules

PaginationParams represents request parameters only.

It is considered a Plain Class.

Allowed:

- copyWith
- toMap

Not required:

- fromJson
- Equatable
- backend serialization

---

# 11. Generic Data Wrappers

Sometimes the backend returns only raw data.

Instead of creating unnecessary wrapper models, use generic wrappers.

Examples:

dart
ListData<T>


dart
SingleData<T>


These classes should simply expose:

dart
data


through:

dart
LoadableResponse<T>


No additional logic should exist.

---

## Wrapper Responsibility

Generic wrappers exist only to standardize API return types.

Examples:

dart
SingleData<T>


dart
ListData<T>


They should never contain:

- business logic
- parsing logic
- pagination logic

They simply expose:

dart
data


through `LoadableResponse<T>`.

---

# 12. Base State Classes

## Purpose

Base State classes centralize shared request behavior.

Example:

dart
RequestState


---

## Responsibilities

Base states may contain:

- request status
- message
- callbacks
- shared side effects

They should eliminate duplicated state handling across features.

---

## Rules

Base State classes:

- should be abstract
- should not depend on feature-specific models
- should expose reusable request behavior
- may trigger centralized side effects

---

## Toast Rule

Shared request states should use centralized components.

Example:

dart
AppToast.showToast(...)


Never recreate toast behavior inside feature states.

---

## RequestStatus Rule

Request lifecycle should be represented using:

dart
RequestStatus


Typical values:

- loading
- success
- failure

Avoid creating custom status implementations per feature.

---

## Shared Request Behavior

Base state classes are allowed to centralize common request handling.

Typical shared responsibilities include:

- displaying success messages
- displaying failure messages
- invoking completion callbacks
- invoking retry callbacks

This prevents every feature from reimplementing the same request lifecycle.

---

## Feature Independence Rule

Base state classes must remain feature-agnostic.

They must never depend on:

- ProductModel
- OrderModel
- UserModel

or any other feature-specific type.

Only shared request behavior belongs here.

---

# 13. Architecture Decision Tree

Before creating any class, determine its responsibility.

| Purpose | Class Type |
|----------|------------|
| Backend object | Data Model |
| API wrapper | Response Model |
| UI representation | Entity |
| Helper / Service | Plain Class |
| Shared response behavior | Base Contract |
| Shared request behavior | Base State |

---

# 14. Final Philosophy

Every class must have exactly one architectural responsibility.

The AI should always classify a class before creating it.

Never force every class to behave like a Model.

Instead:

- Models represent backend data.
- Response Models wrap backend responses.
- Entities represent UI.
- Plain Classes provide logic.
- Base Contracts define reusable APIs.
- Base State Classes centralize shared request behavior.

Keeping these responsibilities separated ensures a clean, scalable, and predictable architecture.
