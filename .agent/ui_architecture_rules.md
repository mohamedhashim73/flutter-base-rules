# UI Architecture Rules — Flutter Project

---

## 1. Overview

This document defines the complete UI architecture rules for the project.

The UI layer is responsible only for:

* rendering widgets
* composing pages
* displaying state
* delegating actions to Cubits

> UI MUST NOT contain business logic or state decisions.

---

# 2. Page Structure Rules

## 2.1 Page Responsibility

Each page is:

* a composition layer only
* responsible for arranging widgets
* not responsible for logic or state management

---

## 2.2 Page Size Rule

* Maximum page size: 150 lines
* If exceeded:

  * split into sub-widgets
  * move logic to Cubits
  * extract reusable components

---

## 2.3 Page Structure Pattern

Every page must follow:

txt
Page
 ├── Header Widget
 ├── Form / Content Widget
 ├── Action Widgets
 ├── Footer Widget


---

## 2.4 Forbidden in Pages

❌ Business logic  
❌ API calls  
❌ State decisions  
❌ Controller creation  
❌ FormKey creation  
❌ Dependency injection calls  
❌ Complex conditions  
❌ Data transformation logic  
❌ Inline filtering or mapping logic  
❌ Direct service usage  
❌ Large inline widget trees  

---

# 3. Sub-Widgets Rules

## 3.1 Purpose

Sub-widgets are used to:

* split UI into readable blocks
* improve reuse
* reduce page size
* hide implementation details behind clear component names

---

## 3.2 Structure Rule

Each feature has:

txt
views/{feature}/widgets/


Example:

txt
login/
 ├── login_header_widget.dart
 ├── login_form_widget.dart
 ├── login_button_widget.dart
 ├── login_footer_widget.dart


---

## 3.3 Widget Responsibility

Widgets are:

* purely UI
* stateless when possible
* receive all dependencies via constructor
* focused on one visual responsibility

---

## 3.4 Forbidden in Widgets

❌ Cubit creation  
❌ Service calls  
❌ Business logic  
❌ Navigation logic decisions  
❌ State mutation  
❌ Filtering data  
❌ Mapping response data  
❌ Dependency injection calls  

---

## 3.5 One Class Per File Rule

Each UI file MUST contain only one widget/class.

---

### Forbidden

❌ Multiple widgets/classes inside the same file

dart
class SupplierDetailsPage extends StatefulWidget {}

class SupplierTransactionsSectionWidget extends StatelessWidget {}

class SupplierActionsWidget extends StatelessWidget {}


---

### Correct Pattern

Each widget must have its own file:

txt
supplier_details_page.dart
supplier_transactions_section_widget.dart
supplier_actions_widget.dart


---

### Goal

This keeps files:

* simple
* readable
* focused
* easy to navigate
* AI-friendly

---

# 4. State Management Rules (UI Side)

## 4.1 Bloc Usage Rule

* Use `BlocBuilder` ONLY where UI must rebuild
* Never wrap full page unless required

---

## 4.2 Scoped Rebuild Rule

✔ Rebuild only affected widget areas  
❌ Do not wrap entire page with BlocBuilder unless necessary

---

## 4.3 Shared Rebuild Optimization

If multiple widgets depend on the same state:

✔ Wrap the nearest shared parent widget once  
❌ Do not wrap every child separately

---

## 4.4 Single Widget Rebuild Rule

If only one widget changes:

✔ Wrap ONLY that widget with `BlocBuilder`

---

## 4.5 Forbidden Bloc Patterns

❌ Nested unnecessary BlocBuilders  
❌ Wrapping entire Scaffold unnecessarily  
❌ Rebuilding static widgets  
❌ Using BlocBuilder for non-changing widgets  

---

## 4.6 No Logic Inside Builder

❌ No business logic inside:

dart
builder: (context, state)


❌ No state interpretation logic  
❌ No filtering  
❌ No API condition handling  
❌ No data transformation  
❌ No side effects  

✔ Builder should ONLY render UI

---

## 4.7 State Responsibility Rule

Cubit/State handles:

* toast logic
* success actions
* failure actions
* callbacks
* request handling decisions

UI only reacts visually.

---

## 4.8 No listenWhen/buildWhen Overengineering

❌ Avoid unnecessary:

* `listenWhen`
* `buildWhen`

Unless truly needed for performance.

Default architecture should remain simple and readable.

---

## 4.9 DataStateBuilderWidget Rule

All async UI MUST use `DataStateBuilderWidget`.

UI should construct only:

dart
DataState(
  state: state,
  response: cubit.data,
)


Example:

dart
DataStateBuilderWidget(
  dataState: DataState(
    state: state,
    response: cubit.products,
  ),
  widget: ProductsWidget(),
)


`DataStateBuilderWidget` is responsible for rendering:

- loading
- success
- empty
- error

UI MUST NOT manually decide which widget to render based on async state.

---

# 5. Dependency Injection Rules (UI Layer)

## 5.1 Forbidden Rule

❌ NO `sl<T>()` inside UI

---

## 5.2 Correct Pattern

Dependencies must be injected from outside:

dart
ProductsPage(
  cubit: cubit,
  actionsCubit: actionsCubit,
)


---

## 5.3 Responsibility Split

| Layer             | Responsibility       |
| ----------------- | -------------------- |
| Composition Layer | inject dependencies  |
| UI Layer          | consume dependencies |

---

## 5.4 Cubit Access Rules

Cubit instances MUST be retrieved from the dependency injection layer using `sl()`.

---

### StatelessWidget Rule

Inside `StatelessWidget`:

✔ Retrieve Cubit inside `build()` only if needed.

Example:

dart
@override
Widget build(BuildContext context) {
  final ProductsCubit cubit = sl<ProductsCubit>();

  return Scaffold(
    body: ProductsBodyWidget(cubit: cubit),
  );
}


---

### StatefulWidget Rule

Inside `StatefulWidget`:

✔ Retrieve Cubit once as a class field outside `build()`.

Example:

dart
class _ProductsPageState extends State<ProductsPage> {
  final ProductsCubit cubit = sl<ProductsCubit>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProductsBodyWidget(cubit: cubit),
    );
  }
}


---

### Forbidden

❌ `context.read<Cubit>()`

❌ `context.watch<Cubit>()`

❌ `BlocProvider.of(context)`

❌ Creating Cubits manually.

❌ Calling `sl<Cubit>()` multiple times inside the same widget.

---

### Goal

Every UI widget retrieves its Cubit from the centralized dependency injection system while respecting the widget lifecycle:

- `StatelessWidget` → retrieve inside `build()`.
- `StatefulWidget` → retrieve once outside `build()`.

---

# 6. Controllers & Form Rules

## 6.1 Rule

❌ No controllers inside UI  
❌ No FormKey inside UI

---

## 6.2 Correct Location

All must live inside Cubit:

* TextEditingController
* FocusNode
* GlobalKey<FormState>

---

## 6.3 UI Usage

UI only receives:

dart
controller: cubit.emailController
formKey: cubit.formKey


---

# 7. Extensions Usage Rules

UI MUST use extensions instead of raw logic.

Examples:

* `.paddingOnly()`
* `.vrSpace`
* `context.crossAxisCount`
* `context.padding`

---

## 7.1 Forbidden

❌ Manual repeated padding  
❌ Duplicated spacing logic  
❌ Repeated MediaQuery calculations  
❌ Repeated responsive calculations  

---

## 7.2 Preferred Pattern

✔ Reusable extension methods  
✔ Readable UI syntax  
✔ Short widget trees  

---

# 8. Navigation Rules (UI Side)

## 8.1 Rule

❌ No raw Navigator usage inside UI

---

## 8.2 Rule

Navigation must use centralized system:

* `AppRoutes.push`
* `AppRoutes.pop`
* `AppRoutes.pushAndRemovePreviousRoutes`

---

## 8.3 Rule

❌ No navigation decision logic inside widgets  
✔ Navigation triggered via callbacks or Cubit

---

# 9. UI Composition Philosophy

UI follows:

> "Compose, don’t compute"

Meaning:

* UI composes widgets
* Cubits compute logic
* Extensions handle styling
* Pages expose abstraction, not implementation details

---

# 10. Performance Rules

## 10.1 Rebuild Optimization

✔ Keep rebuild scopes small  
✔ Extract rebuildable sections into widgets  
✔ Avoid rebuilding large widget trees  

---

## 10.2 Const Constructors

Use `const` whenever possible.

---

## 10.3 Widget Splitting Rule

If widget tree becomes large:

✔ Split into feature widgets  
✔ Keep readability high  

---

# 11. Readability Rules

## 11.1 Widget Tree Readability

✔ Prefer clean vertical layout  
✔ Avoid deep nesting  
✔ Extract repeated UI  

---

## 11.2 Variable Rule

❌ Avoid unnecessary local variables inside UI

Bad:

dart
final product = cubit.products[index];


if used once.

Good:

dart
product: cubit.products[index]


---

## 11.3 UI Simplicity Rule

UI code should feel:

* predictable
* short
* readable
* compositional

---

## 11.4 Local Variables Rule

✔ Create local variables if they:

* reduce repeated conditions
* improve readability
* simplify state checks

Good:

dart
final isLoading =
    state is GetPoliciesState &&
    state.status == RequestStatus.loading;


---

❌ Do not create unnecessary variables for single-use values.

---

# 12. Async UI Rules

## 12.1 Async Handling

Async operations are represented through `DataState`.

UI constructs only:

dart
DataState(
  state: state,
  response: cubit.data,
)


The rendering of:

- loading
- success
- empty
- error

is handled entirely by `DataStateBuilderWidget`.

---

## 12.2 Cached Data Priority

When cached/local data already exists inside Cubit,
the UI should continue displaying it during refresh.

This behavior is determined automatically by `DataState`.

UI MUST NOT manually check:

dart
state.status


or

dart
cubit.data.isNotEmpty


before rendering.

---

## 12.3 Retry Handling

Retry callbacks are passed directly to `DataStateBuilderWidget`.

Example:

dart
DataStateBuilderWidget(
  dataState: DataState(
    state: state,
    response: cubit.products,
  ),
  onFailure: cubit.getProducts,
)


UI should never manually switch between retry widgets.

---

# 13. Component Abstraction Rules

## 13.1 Page Must Use Components

Pages MUST be made of high-level components only.

A page should look like:

txt
SupplierDetailsPage
 ├── SupplierInfoCardWidget
 ├── SupplierBalanceCardWidget
 ├── SupplierTransactionsSectionWidget
 └── SupplierActionsFabWidget


---

## 13.2 Abstraction Philosophy

Pages should expose abstraction, not implementation details.

The page should show WHAT exists, not HOW it is built.

---

# 14. Anti-Patterns (STRICTLY FORBIDDEN)

❌ Business logic in UI  
❌ API calls in UI  
❌ Cubit instantiation in UI  
❌ Duplicate widgets  
❌ Hardcoded styling  
❌ Direct navigation logic  
❌ Controllers inside widgets  
❌ Complex conditional rendering in page  
❌ Dependency injection inside widgets  
❌ Filtering data inside UI  
❌ Mapping response data inside UI  
❌ Service usage inside widgets  
❌ Overusing BlocBuilder  
❌ Rebuilding entire page unnecessarily  
❌ Large widget files  
❌ Manual repeated spacing logic  
❌ Multiple widget classes in one file  
❌ Large widget-returning methods  

---

# 16. Additional UI Architecture Rules

## 16.1 UI Must NOT Handle Side Effects

UI layer exists for rendering only.

---

### Forbidden in UI

❌ `BlocListener` for business logic

❌ `BlocConsumer` unless absolutely required for UI-only behavior

❌ navigation decisions

❌ success/failure handling

❌ toast/snackbar handling

❌ triggering Cubit orchestration

❌ reacting to state with business logic

---

### Correct Rule

Cubit decides what happens.

State executes side effects.

UI only rebuilds.

Examples of side effects handled by Cubit/State:

* navigation
* success callbacks
* toast/snackbar
* cache updates
* chained actions
* reload logic

---

## 16.2 UI Must NOT Define Business Methods

UI MUST NOT contain helper methods that orchestrate Cubits.

---

### Forbidden

❌ refresh methods

❌ reload methods

❌ multiple Cubit calls

❌ orchestration methods

Example:

dart
Future<void> _refreshData() async {
  await productsCubit.getProducts(refresh: true);
  reportsCubit.loadReports();
}


---

### Correct Rule

Move orchestration into Cubit.

UI calls only:

dart
cubit.refresh();


or

dart
cubit.init();


---

## 16.3 UI Must NOT Hold Business State

UI should remain stateless whenever possible.

---

### Forbidden Variables

❌ counters

❌ cached lengths

❌ selected indexes

❌ filters

❌ lists/maps

❌ business flags

❌ business-related state

Example:

dart
int _lastProductsCount = -1;


---

### Correct Rule

Business state belongs inside Cubit.

UI should only keep rendering-related state when absolutely necessary.

---

## 16.4 Flutter UI Controllers Rule

UI may own Flutter rendering controllers ONLY when they are tightly coupled to the widget lifecycle and cannot reasonably live inside Cubit.

Examples:

* `AnimationController`
* `TabController`
* `PageController`
* `ScrollController`

These controllers exist purely for rendering.

All business-related controllers MUST remain inside Cubit.

Examples:

* `TextEditingController`
* `FocusNode`
* `GlobalKey<FormState>`

---

## 16.5 No Widget Builder Methods

UI files MUST NOT contain large widget-returning methods.

---

### Forbidden

dart
Widget _buildOverviewCard(BuildContext context)


---

### Correct Pattern

Extract it into its own widget file.

Example:

txt
overview_card_widget.dart


---

## 16.6 Widget Extraction Rule

If a widget contains:

* styling
* layout
* nested widgets
* repeated UI
* business-related composition

then it MUST become a separate widget.

Pages should contain high-level widgets only.

---

## 16.7 Repeated UI Rule

Avoid duplicated layout widgets.

Instead of repeatedly writing:

dart
SizedBox(height: Dim.vSpace)


Prefer reusable extensions such as:

dart
Widget().paddingSymmetric(...)


or reusable spacing extensions/components.

---

## 16.8 UI Initialization Rule

UI lifecycle should remain minimal.

---

### Allowed in initState

Only Cubit initialization.

Example:

dart
@override
void initState() {
  super.initState();
  cubit.init();
}


---

### Forbidden

❌ multiple API calls

❌ chained Cubit calls

❌ Firebase setup

❌ listeners

❌ orchestration

❌ business decisions

All initialization belongs inside Cubit.

---

## 16.9 UI Dispose Rule

UI should not dispose business resources.

Cubit is responsible for disposing:

* controllers

* streams

* subscriptions

* feature cleanup

UI disposes only rendering-related controllers such as:

* AnimationController

* TabController

* PageController

* ScrollController

---

## 16.10 Async Rendering Rule

Async rendering MUST be delegated to `DataStateBuilderWidget`.

UI constructs only:

dart
DataState(
  state: state,
  response: cubit.data,
)


Example:

dart
DataStateBuilderWidget(
  dataState: DataState(
    state: state,
    response: cubit.products,
  ),
  widget: ProductsBodyWidget(),
)


UI MUST NOT manually decide:

* loading

* success

* empty

* error

Those decisions belong to `DataStateBuilderWidget`.

---

## 16.11 Composition Philosophy

UI should look like:

txt
Page
 ├── Widgets
 ├── BlocBuilders
 ├── Layout
 └── Visual Composition


NOT:

txt
Page
 ├── Business Logic
 ├── Decisions
 ├── Side Effects
 ├── Orchestration
 └── Data Processing


---

# 17. Design Goal

This architecture ensures:

* high readability
* predictable widget trees
* reusable UI components
* minimal UI responsibilities
* centralized business logic
* optimized rebuilds
* scalable architecture
* AI-friendly code generation