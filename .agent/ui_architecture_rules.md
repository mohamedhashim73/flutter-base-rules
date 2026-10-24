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

Keep pages small enough that their composition is clear at a glance. A line
count is a review signal, not a hard architectural boundary.

Extract a section when it has an independent visual responsibility, rebuild
scope, test surface, or reuse value. Move feature logic to the Cubit and share
components only when their behavior is genuinely reusable.

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

### Content Decisions vs Presentation

The Cubit, model, or service decides what data is visible and why. This includes
filtering, sorting, searching, pagination, permissions, derived collections,
counts, totals, and any transformation that changes feature behavior or visible
content. UI builders may perform only loop and index mechanics over data that
is already prepared for rendering.

Name exposed values by their domain meaning, such as `activeStores` or
`recentExpenses`, rather than their implementation detail, such as
`filteredList`.

The UI owns local presentation: layout composition, styles, and simple display
formatting. When display mapping is complex or repeated across widgets, place
it in a feature presentation mapper or view model instead of mixing it into a
widget or a domain model.

Do not use a Cubit getter to hide expensive repeated work. If a derived
collection is costly, calculate or cache it when its source data or criteria
changes.

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

# 5. Explicit Cubit Injection Rules (UI Layer)

## 5.1 Page Ownership

The feature page is the only UI boundary allowed to resolve its Cubit instances
from the service locator using `sl<T>()`. It owns one instance for the feature
scope and passes that same instance to every descendant, including dialogs,
bottom sheets, and responsive layout branches.

## 5.2 Constructor Injection

Subwidgets receive the Cubit they need through a required constructor parameter.
They must not resolve it themselves.

```dart
// Page
final productsCubit = sl<ProductsCubit>();

ProductsBodyWidget(cubit: productsCubit);

// Subwidget
class ProductsBodyWidget extends StatelessWidget {
  final ProductsCubit cubit;

  const ProductsBodyWidget({required this.cubit});
}
```

## 5.3 Bloc Usage

This architecture uses explicit Cubit parameters, not `BlocProvider` lookup.
Pass the injected instance directly to `BlocBuilder`, `BlocListener`, and
`BlocConsumer`:

```dart
BlocBuilder<ProductsCubit, ProductsState>(
  cubit: cubit,
  builder: (context, state) => const SizedBox(),
)
```

## 5.4 Forbidden

❌ `sl<Cubit>()` in a subwidget, dialog, or bottom sheet
❌ `context.read<Cubit>()` or `context.watch<Cubit>()`
❌ `BlocProvider.of(context)` or `BlocProvider`
❌ manually creating a Cubit inside UI
❌ resolving the same Cubit repeatedly within one feature tree

## 5.5 Cubit-to-Cubit Dependencies

A Cubit must not resolve another Cubit through `sl()`. If coordination is
necessary, inject that dependency through the constructor and register the
wiring in the dependency-injection setup. Prefer depending on a service,
repository, or use case when the dependency represents shared business work.

## 5.6 Goal

Explicit injection preserves one source of truth, avoids duplicate subscriptions,
keeps responsive branches synchronized, and makes widgets directly testable
with fake Cubits.

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

## 6.4 Form Flow and Transient Form State

The Cubit owns the complete form flow:

* validation and submit methods
* request execution and request-status decisions
* form toggle values, such as password visibility
* domain-specific derived flags, such as `isSubmitting` or `isSavingProfile`

UI only renders those values and calls the Cubit methods. It MUST NOT validate,
submit, or manage a form toggle with `setState`.

❌
```dart
bool _obscurePassword = true;

Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isSubmitting = true);
  await cubit.signIn();
}
```

✔
```dart
// Cubit
bool obscurePassword = true;
int _formRevision = 0;
bool get isSubmitting => state is SignInState &&
    state.status == RequestStatus.loading;

void togglePasswordVisibility() {
  obscurePassword = !obscurePassword;
  emit(SignInFormChangedState(revision: ++_formRevision));
}

Future<void> submit() async {
  if (!formKey.currentState!.validate()) return;
  // Execute the sign-in request.
}

// UI
onTap: cubit.submit,
obscureText: cubit.obscurePassword,
isLoading: cubit.isSubmitting,
```

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

## 7.3 Spacing and Padding Rule

Use the established padding and spacing extensions for repeated design spacing
and simple padding wrappers. Use the project's spacing tokens rather than
scattered magic numbers.

For a uniform gap between every child of a `Row` or `Column`, prefer its
`spacing:` parameter. Do not combine `spacing:` with manual spacer widgets for
the same gap.

The parent owns spacing between sibling widgets. Put padding on the child only
when that space is part of the child's visual design or touch area. Use a
parent-owned spacer or padding for an intentionally non-uniform layout gap.

`const SizedBox.shrink()` is allowed for an empty placeholder. A `const
SizedBox` is also allowed when it preserves a useful const widget tree or is
clearer than an extension. Do not add an extension for a rare one-off case;
add one only when it is broadly reusable.

Use existing context extensions for repeated screen-level sizing. When a
widget must react to its own available size, use `LayoutBuilder` and its local
constraints instead of screen-wide `MediaQuery` calculations.

---

## 7.4 Adaptive Composition Rule

Reuse components that represent the same content or interaction across narrow
and wide layouts. Do not duplicate form fields, titles, item renderers,
buttons, validation, feature logic, controllers, or Cubit state merely because
the available size changes.

Layout composition may differ when the information hierarchy or interaction
pattern genuinely changes, such as a column becoming a row, a bottom sheet
becoming a side panel, or a list becoming a table. Keep a single composition
when the difference is limited to sizing, spacing, or column count.

Every adaptive branch must receive the same existing Cubit instances and
preserve relevant widget keys and state. A resize or orientation change must
not discard in-progress input, selection, or other feature state.

Neither portrait nor landscape is inherently the source of truth. Follow the
product's design requirements for each mode and share the semantic components
where possible.

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

## 8.4 Dialog, Sheet, Picker, and Effect Rule

The UI layer constructs, opens, closes, and hosts dialogs, bottom sheets,
pickers, navigation, and other presentation surfaces. A Cubit MUST NOT import
widget files, build a `Widget`, call a global navigator, or directly open or
close a presentation surface.

The Cubit owns feature data, validation, and the operation performed from a
surface. It exposes the result as state or an explicit effect; a UI listener or
the feature root performs the corresponding presentation action.

Dialog and sheet content receive the existing Cubit through constructor
injection. A UI-only helper that opens a repeated presentation surface is
allowed when it stays in the UI layer and does not hide business logic.

Native pickers are presentation effects. The UI opens the picker and sends its
result to a Cubit method, which validates and stores the feature value.

Form validation through a `FormKey` requires a mounted form. Do not submit when
`formKey.currentState?.validate()` is not `true`; apply additional business
validation in the Cubit as needed.

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

Use `const` whenever it improves the widget tree without making the code less
clear. The spacing and padding guidance in §7.3 defines its explicit layout
exceptions.

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

Inline a simple value that is used once:

```dart
product: cubit.products[index]
```

Do not force a meaningful presentation-only value inline merely because it is
used once. A local is allowed when it makes a complex expression or visual
condition materially clearer:

```dart
final hasLongTitle = title.length > maxTitleLength;
```


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

* are reused in the same file
* improve readability of a complex expression
* name a meaningful presentation-only concept

They MUST NOT interpret state, transform feature data, or make a business
decision. Expose that value from the Cubit or model instead.

```dart
// Cubit
bool get isLoading =>
    state is GetPoliciesState &&
    state.status == RequestStatus.loading;

// UI
isLoading: cubit.isLoading,
```

---

## 11.5 Value Placement Rule

Put reusable values and logic in the narrowest appropriate location:

* business or domain logic → Cubit, model, or service
* reusable value transformation with a natural receiver → extension
* app-wide shared configuration or display data → `core/constants`
* feature-shared configuration or display data → that feature's constants file
* widget-only, immutable display data → a private top-level or `static const`

Do not move widget-specific data to global constants merely to centralize it,
and do not use an extension for logic that belongs to the domain layer.

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

UI MUST NOT own feature, form, request, or derived state.

`setState` MUST NOT manage a value that affects a feature's business flow, form
flow, request status, loading state, filter, selection, or derived UI decision.
Those values belong to the Cubit and UI rebuilds through emitted state.

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

UI may keep only narrowly scoped presentation state that is tied to a rendering
controller and cannot reasonably live in a Cubit. It must not represent feature
or form state.

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

Avoid repeated padding wrappers and duplicated spacing choices. Reuse the
established extensions and spacing tokens where they improve consistency; see
§7.3 for the ownership and exception rules.

---

## 16.8 UI Initialization Rule

UI lifecycle should remain minimal.

---

### Allowed in initState

The feature root may trigger the Cubit's single initialization method once for
each feature lifecycle instance. Descendant widgets, dialogs, bottom sheets,
and responsive branches only render; they must not trigger initialization,
fetching, or refresh work.

Example:

```dart
@override
void initState() {
  super.initState();
  cubit.init();
}
```

Call `addPostFrameCallback` only when the work genuinely requires a mounted
`BuildContext` after the first frame. Do not use it as the default way to start
a Cubit.

Initial setup is distinct from user-driven work. Pull-to-refresh, retry, and
changes to filters or account scope must call explicit Cubit methods such as
`refresh()`; they must not re-run `init()`.


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
