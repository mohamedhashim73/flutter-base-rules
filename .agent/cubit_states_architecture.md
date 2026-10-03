# Cubit & States Architecture System

---

# 1. Overview

This document defines the complete architecture for Cubits and States across the project.

Its goals are:

- predictable business logic
- reusable patterns
- centralized request handling
- clean separation from UI
- scalable feature implementation
- consistent state management

Every feature should follow this architecture regardless of whether it uses:

- REST APIs
- Local Cache
- Local Database
- Firebase
- Streams

---

# 2. Core Philosophy


Cubit  = Business Layer
State  = Communication Layer
UI     = Presentation Layer


Every layer has a single responsibility.

---

## Cubit Responsibilities

Cubit owns the entire feature state.

Including:

- API requests
- Firebase requests
- Local database operations
- Cache management
- Search
- Filtering
- Sorting
- Validation
- Pagination
- Controllers
- FormKeys
- FocusNodes
- Stream subscriptions
- Timers
- Business decisions
- Feature initialization
- Feature disposal
- Navigation orchestration
- Chained operations

Cubit is the only place that knows how the feature works.

---

## State Responsibilities

State is responsible for communicating Cubit changes.

State may carry:

- request status
- success message
- failure message
- callbacks
- UI refresh signal

Action states may also execute predefined side effects through `handleActionState()`.

State MUST NOT contain:

- business logic
- API calls
- Firebase calls
- widget logic
- rendering logic

---

## UI Responsibilities

UI is responsible only for:

- rendering widgets
- composing layouts
- reading Cubit data
- calling Cubit methods
- rebuilding when state changes

UI MUST NOT contain:

- business logic
- state decisions
- side effects
- request handling
- navigation decisions
- filtering
- searching
- validation

---

# 3. Request Status System

Async operations use:

dart
enum RequestStatus {
  loading,
  success,
  failure,
}


Used for:

- GET
- POST
- PUT
- PATCH
- DELETE
- Firebase requests
- Heavy async operations

NOT used for:

- simple UI selections
- toggles
- local variables
- animations

---

# 4. Standard State Structure

Every async state should follow:

dart
class ExampleState extends FeatureStates {
  const ExampleState({
    super.status,
    super.message,
    super.onDone,
    super.onTap,
  });
}


Meaning:

- status → current request state
- message → user feedback
- onDone → success callback
- onTap → callback for retry/open/etc.

State should NOT introduce additional request fields unless required.

---

# 5. RequestState Base Class

All feature states should inherit from `RequestState`.

Responsibilities include:

- storing request status
- storing feedback message
- storing callbacks
- executing action states

Example:

dart
abstract class RequestState {

  final RequestStatus? status;

  final String? message;

  final VoidCallback? onDone;

  final VoidCallback? onTap;

}


Action states may call:

dart
handleActionState();


to execute:

- success toast
- failure toast
- success callback

without involving the UI.

---

## ActionStateMixin

`ActionStateMixin` is a mixin defined on `RequestState`:

dart
mixin ActionStateMixin on RequestState {}


It marks a state as self-handled (action state).

`DataState` checks `state is ActionStateMixin` and if true, completely ignores the state's `status` for page UI decisions. This means:

- the page never shows an error widget due to an action failure
- the page never shows a loading shimmer due to an action loading state
- the action's toast fires normally via `handleActionState()`
- the data UI is unaffected

Every class that calls `handleActionState()` MUST mix in `ActionStateMixin`. See section 14.

---

# 6. State Categories

There are only two categories.

---

## UI State

Used for rebuilding widgets.

Examples:

dart
GetProductsState

GetOrdersState

GetProfileState


These states should only carry request information.

---

## Action State

Used for operations such as:

- create
- update
- delete
- login
- logout
- checkout

Action states may execute:

dart
handleActionState();


inside their constructor.

Example:

dart
class CreateOrderActionState extends OrdersStates {

  CreateOrderActionState({
    required super.status,
    super.message,
    super.onDone,
    super.onTap,
  }) {
    handleActionState();
  }

}


---

# 7. Cubit Responsibilities

Cubit owns every feature resource.

Including:

text
Models

Lists

Maps

Selected items

Controllers

FocusNodes

FormKeys

Timers

Subscriptions

Pagination

Search

Validation

Cached data


Everything belongs inside Cubit.

Never inside UI.

---

# 8. Data Ownership Rule

Cubit is the single source of truth.

Example:

dart
ProductsResponse? products;


Good.

Avoid unnecessary duplication such as:

dart
ProductsResponse? _products;

ProductsResponse? products;


unless the getter provides additional behavior.

Example of a valid getter:

dart
Map<String, PersonModel> get people {

    return searchController.text.isEmpty
        ? _people
        : _filteredPeople;

}


Otherwise, keep only one variable.

---

# 9. Search & Filtering

Search belongs inside Cubit.

Filtering belongs inside Cubit.

Sorting belongs inside Cubit.

UI only sends user input.

Example:

dart
void filterProducts() {

    final query = searchController.text;

    ...

    emit(GetProductsState(
        status: RequestStatus.success,
    ));

}


UI never filters data.

---

# 10. Controllers Rule

Cubit owns every feature controller.

Including:

- TextEditingController
- FocusNode
- GlobalKey<FormState>
- ScrollController
- SearchManager
- PaginationManager
- StreamSubscription
- Timer

Controllers must:

- initialize inside Cubit
- dispose inside Cubit
- never be created inside UI

UI only consumes them.

Example:

dart
controller: cubit.searchController


Never:

dart
final controller = TextEditingController();


inside a widget.

# 11. Cubit Lifecycle Rule

---

## Core Principle

Feature initialization and cleanup belong to Cubit.

UI lifecycle should remain minimal.

---

## Initialization

Each feature should expose a single initialization method.

Example:

dart
Future<void> init() async {
  initSearchController();
  initScrollController();
  await getProducts(refresh: true);
}


UI should only call:

dart
@override
void initState() {
  super.initState();
  cubit.init();
}


NOT:

dart
searchController = ...
scrollController = ...
getProducts();
getCategories();
listenProducts();


---

## Dispose

Cubit should expose a single cleanup method when needed.

Example:

dart
Future<void> disposeFeature() async {
  search.dispose();
  scroll.dispose();
  subscription?.cancel();
}


UI only calls:

dart
@override
void dispose() {
  cubit.disposeFeature();
  super.dispose();
}


---

# 12. Request Handling Philosophy

All request execution should be centralized.

Cubit should never duplicate:

- loading handling
- success handling
- failure handling
- pagination merging
- cache loading

Shared request logic belongs to helper classes such as:

text
RequestHelper


or future helpers for Firebase.

Cubit only provides:

- endpoint
- parser
- callbacks
- current data
- refresh/reset flags

---

# 13. Error Handling

Errors should always be converted before reaching UI.

Use:

dart
ErrorHandler.error(...)


inside:

- Cubit
- RequestHelper

Never inside UI.

State carries only:

dart
message


Example:

dart
emit(
    GetProductsState(
        status: RequestStatus.failure,
        message: ErrorHandler.error(error),
    ),
);


---

# 14. Action States

Action states represent operations like:

- Create
- Update
- Delete
- Login
- Logout
- Checkout
- Send OTP

Action state should call:

dart
handleActionState();


inside constructor.

Example:

dart
class CreateOrderActionState extends OrdersStates with ActionStateMixin {

  CreateOrderActionState({
    required super.status,
    super.message,
    super.onDone,
    super.onTap,
  }) {
    handleActionState();
  }

}


UI does nothing except rebuilding.

---

## CRITICAL: ActionStateMixin Rule

Every action state class MUST also mix in `ActionStateMixin`:

dart
class MyActionState extends FeatureStates with ActionStateMixin {


**Why this is mandatory:**

`DataState` — the object passed to `DataStateBuilderWidget` — evaluates `status` from the emitted state to decide whether to show loading, error, empty, or success UI.

If an action state with `status: failure` is emitted, and `ActionStateMixin` is NOT applied, `DataState` will treat it as a page-level failure and replace the entire page UI with an error widget — even though the page data is still valid and only the action failed.

`ActionStateMixin` tells `DataState` to ignore this state entirely for page UI rendering. The action state still shows its toast via `handleActionState()` — it just never corrupts the data UI.

**The rule:**

- Any state whose constructor calls `handleActionState()` → MUST have `with ActionStateMixin`
- Any state that does NOT call `handleActionState()` → must NOT have `with ActionStateMixin`
- Never call `handleActionState()` without `ActionStateMixin` — it will break page UI on failure

---

## CRITICAL: Do NOT mix ActionStateMixin on base or initial states

Only the specific action state class gets `with ActionStateMixin`.

Wrong:

dart
abstract class OrdersStates extends RequestState with ActionStateMixin { ... }

class OrdersInitialState extends OrdersStates { ... }

class CreateOrderActionState extends OrdersStates { ... } // all inherit mixin — wrong


Right:

dart
abstract class OrdersStates extends RequestState { ... }

class OrdersInitialState extends OrdersStates { ... }

class CreateOrderActionState extends OrdersStates with ActionStateMixin {
  CreateOrderActionState({...}) { handleActionState(); }
}


Only the class that calls `handleActionState()` gets the mixin.

---

# 15. Request Flow

Every async operation should follow:

text
UI
↓

Cubit Method

↓

Request Helper

↓

API / Firebase

↓

Result

↓

State

↓

UI rebuild


There should be no additional layer inside UI.

---

# 16. Dependency Injection

Dependency Injection belongs to GetIt.

Use:

dart
sl<T>()


---

## Inside Cubit

Dependencies should be injected once.

Example:

dart
final ApiServices api = sl<ApiServices>();


or

dart
final CacheManager cache = sl<CacheManager>();


---

## Inside StatelessWidget

Retrieve Cubit inside build only if needed.

dart
@override
Widget build(BuildContext context) {

    final ProductsCubit cubit = sl<ProductsCubit>();

    ...

}


---

## Inside StatefulWidget

Retrieve Cubit once.

dart
late final ProductsCubit cubit;

@override
void initState() {
    super.initState();
    cubit = sl<ProductsCubit>();
}


Never recreate Cubits.

---

# 17. Performance Rules

Cubit should emit only when required.

Avoid:

dart
emit(...);
emit(...);
emit(...);


without state changes.

Avoid duplicated requests.

Avoid duplicated parsing.

Avoid duplicated cache updates.

Keep Cubits predictable.

---

# 18. Feature State Rules

Feature data belongs only to Cubit.

Examples:

dart
UserModel?

ProductsResponse?

Map<String, ProductModel>

List<CategoryModel>

PaginationModel


Never duplicate feature state inside UI.

---

# 19. Request Messages

Every request feedback should use:

dart
message


instead of custom fields.

Example:

dart
emit(

    CreateOrderActionState(

        status: RequestStatus.success,

        message: 'Order created successfully',

    ),

);


State decides how feedback is shown.

UI never shows toast manually.

---

# 20. Callbacks

Only two callbacks are supported.

dart
onDone


Executed after successful action.

Example:

- navigation
- cache update
- chained requests

---

dart
onTap


Used by:

- retry
- open details
- custom toast action

No additional callback fields should be introduced unless absolutely necessary.

---

# 21. UI Communication Contract

Cubit communicates with UI only through:

- state emission
- public getters
- public methods

UI communicates with Cubit only through:

- calling Cubit methods

Nothing else.

---

# 22. Single Source of Truth

Every feature should have exactly one owner for its data.

Owner = Cubit.

Avoid unnecessary duplication.

Bad:

dart
_products

products


Good:

dart
ProductsResponse? products;


Only create getters when adding behavior.

Example:

dart
Map<String, ProductModel> get visibleProducts {

    return search.query.isEmpty
        ? products
        : filteredProducts;

}


---

# 23. Request Helper Responsibility

Request helpers should only execute request workflows.

They must NEVER know:

- UI
- Widgets
- Bloc
- Navigation
- Toast implementation
- Feature-specific business logic

They are generic infrastructure.

---

# 24. Architecture Summary

Responsibilities:

| Layer | Responsibility |
|--------|----------------|
| Cubit | Business Logic |
| RequestHelper | Shared Request Execution |
| State | Communication & Action Contract |
| UI | Rendering Only |

---

# 25. Design Goals

This architecture ensures:

- predictable Cubits
- reusable request execution
- centralized request handling
- centralized action handling
- single source of truth
- minimal UI logic
- clean dependency injection
- scalable feature architecture
- maintainable codebase
- AI-friendly code generation