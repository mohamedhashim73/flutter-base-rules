# Cubit & States Architecture Rules

## 1. Purpose and Scope

This document defines **provider-neutral** state-management rules for Flutter applications using `flutter_bloc` and Cubit. It applies to operations backed by REST APIs, Supabase, local storage, other data sources, or pure in-memory work.

Its scope is **Cubit ownership, states, request orchestration, action feedback, UI communication, lifecycle, and performance**. It does not define REST transport, Supabase queries, persistence APIs, or provider-specific error parsing. Those concerns belong to the SDK, DataSources, Repositories, or their specialized rule files.

**Core principles**

- Cubit owns feature business state and coordinates feature operations.
- States describe changes; creating a State must not itself perform UI side effects.
- UI renders feature state and delegates user actions.
- Repositories abstract feature data access; Cubits do not invoke data clients directly.
- `RequestHelper` is a shared, backend-agnostic request-lifecycle utility.
- Action feedback (toasts and UI callbacks) is handled by one shared listener per applicable Cubit scope, not inside State constructors or Cubit methods.
- Apply each abstraction only when it brings value. Do not add data sources, pagination, or loaders to purely local UI interactions.

---

## 2. Responsibility Boundaries

| Component | Owns | Must not do |
|---|---|---|
| **Cubit** | Feature state, business decisions, operation orchestration, search/filter/sort, applicable controllers and lifecycle | Raw HTTP/Supabase queries, direct persistent storage, Toast/Snackbar rendering, widget composition |
| **Repository** | Feature-oriented data operations, remote/local coordination, cache/fallback policy | Emit Cubit states or render UI |
| **DataSource** | Provider-specific remote/local operations and source-specific mapping | Know about Cubit states, navigation, UI feedback |
| **RequestHelper** | Reusable request execution, result resolution, loading/success/failure lifecycle, locking where needed | Know about widgets, navigation, toasts, particular backend providers or feature rules |
| **RequestState** | Immutable status, message, optional action callbacks | Execute side effects in constructors |
| **ActionStateListener** | React to emitted action success/failure and trigger existing action feedback | Render data, control backend operations, create feature business state |
| **BlocBuilder / DataStateBuilderWidget** | Render only the affected UI | Display toasts or perform navigation as part of `builder` |

Typical persistent-data flow:

```text
UI -> Cubit -> Repository -> DataSource -> SDK / Storage
                          (results return to Cubit)
Cubit -> State -> UI rendering / ActionStateListener
```

A local, synchronous UI choice does **not** need a Repository, DataSource, or `RequestHelper`.

---

## 3. Request Status and Base State Contract

The shared request-status contract is:

```dart
enum RequestStatus { loading, success, failure }
```

Use request statuses for async work with an observable lifecycle. Do **not** introduce a separate request state for every simple toggle, animation, or transient layout decision.

The existing `RequestState` fields remain the shared contract:

```dart
abstract class RequestState {
  final RequestStatus? status;
  final String? message;
  final VoidCallback? onDone;
  final VoidCallback? onTap;

  const RequestState({this.status, this.message, this.onDone, this.onTap});
}
```

- `status`: state of the represented operation; null is allowed for non-request updates.
- `message`: optional user-facing feedback, not an implicit instruction to show a toast.
- `onDone`: optional success **UI** effect; never required for business-critical work.
- `onTap`: optional callback attached to an interactive feedback element (for example, a toast action); do not invoke it just because the State was emitted.
- Feature states inherit these fields via `super` rather than redeclaring them.
- Add feature-specific fields only when needed and include meaningful changes in equality.
- A State class and its constructor should remain free of side effects.

When migrating existing code, an existing `RequestState.handleActionState()` method may be retained **temporarily** as the shared feedback entry point, but it must be invoked **only by the listener**, not by a State constructor. In a later cleanup, presentation-specific toast code can be moved to a dedicated UI feedback handler without changing feature Cubits.

---

## 4. State Categories

### 4.1 Data / Request States

Represent the status and result of fetching or refreshing feature data (list, detail, dashboard, etc.). They may drive loading, success, error, empty, and retry UI.

```dart
class LoadProductsState extends ProductsStates {
  const LoadProductsState({super.status, super.message});
}
```

### 4.2 Action States

Represent commands such as create, update, delete, submit, checkout, sign-in, or other async actions. **Only these states** should mix in `ActionStateMixin` when they use the common action-feedback contract.

```dart
class SaveProductActionState extends ProductsStates with ActionStateMixin {
  const SaveProductActionState({
    super.status,
    super.message,
    super.onDone,
    super.onTap,
  });
}
```

- Do **not** call `handleActionState()` from the constructor.
- An Action State may carry `loading` for a button's `BlocBuilder`.
- The action listener reacts only to final `success` or `failure` states.
- A failed action must **not** replace still-valid page data with a full-screen error.
- Action States that do not need a toast/callback may carry no `message`; a message does not make a State an action by itself.

### 4.3 Presentation / Local Update States

Represent meaningful non-request changes (tab selection, applied filters, expanded sections, etc.) when the Cubit owns that state. They do not need `RequestStatus` or `ActionStateMixin` unless an actual request/action occurs.

**Never put `ActionStateMixin` on the base feature state or initial state.** It belongs only to concrete action states.

---

## 5. Action Feedback: One Listener, Separate Builders

**Decision:** Action feedback is centralized in a standalone `ActionStateListener`, independent of `DataStateBuilderWidget`.

- Wrap the stable feature scope with **one listener per Cubit instance that requires action feedback**, not one listener per button or action.
- A feature that needs no action feedback does not need this listener.
- Keep the listener mounted for the duration of any action whose feedback must be delivered.
- Do not wrap the same Cubit instance with multiple overlapping feedback listeners; that would duplicate toasts/callbacks.
- Use `BlocBuilder` / `BlocSelector` only where UI should rebuild, including an action button's loading state.
- `DataStateBuilderWidget` remains optional and is for data-screen loading/error/empty/success rendering.

Illustrative shared listener (adapt generic bounds/imports to the project's installed `flutter_bloc` version):

```dart
class ActionStateListener<B extends StateStreamable<S>, S extends RequestState>
    extends StatelessWidget {
  final Widget child;

  const ActionStateListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listenWhen: (_, current) =>
          current is ActionStateMixin &&
          (current.status == RequestStatus.success ||
           current.status == RequestStatus.failure),
      listener: (context, state) => state.handleActionState(),
      child: child,
    );
  }
}
```

The snippet reflects a **migration path** using the existing feedback method. Do not assume it exists unchanged in every project: inspect the active `RequestState` and toast infrastructure before implementing. The final implementation should keep UI-specific feedback mechanics outside the State where practical.

Example usage:

```dart
ActionStateListener<ProductsCubit, ProductsStates>(
  child: const ProductsPageContent(),
)
```

A button may still use a small `BlocBuilder` for action loading:

```dart
BlocBuilder<ProductsCubit, ProductsStates>(
  buildWhen: (_, current) => current is SaveProductActionState,
  builder: (context, state) {
    final saving = state is SaveProductActionState &&
        state.status == RequestStatus.loading;
    return ElevatedButton(
      onPressed: saving ? null : () => context.read<ProductsCubit>().save(),
      child: Text(saving ? 'Saving...' : 'Save'),
    );
  },
)
```

**Important:** A builder/filter observing only action states is suitable for isolated controls, not for determining the full data-screen state.

### Action callback behavior

- `onDone` may run on successful action feedback, for navigation, closing a dialog, or another explicitly UI-owned effect.
- Business-critical data mutations, cache synchronization, and necessary chained operations must complete in the Cubit/Repository regardless of whether a listener is mounted.
- `onTap` is passed to the visible feedback action; it is **not** an unconditional request-success callback.
- Make callback invocation once-per-emitted-effect and honor widget lifecycle (`context.mounted` when applicable).
- If an action needs no visible feedback, use an appropriate non-action state or a listener-neutral contract; do not synthesize fake toast messages.

---

## 6. Data State Must Ignore Action States

**Adopt the intended Kenzi behavior:** a `DataState` resolver must ignore `ActionStateMixin` for page-level loading/error/empty decisions.

- `ActionStateMixin` is a marker for action-feedback handling, not data-screen status.
- `ActionState` failure must not produce a page-level error view or erase existing data.
- `ActionState` loading must not replace existing data with a full-screen shimmer.
- Do not use an Action State's `message` as the page-level error message.
- Preserve the actual data and, if needed, the last meaningful **data-request** status independently of action transitions.
- Use `buildWhen`/selectors or explicit data-state tracking where a data builder would otherwise react incorrectly to unrelated states.
- `DataStateBuilderWidget` is optional. Pages without data loading can use ordinary Builders and the standalone ActionStateListener.

Simplified resolver concept:

```dart
static RequestStatus? resolveDataStatus(
  RequestState? state,
  RequestStatus? previousDataStatus,
) {
  if (state is ActionStateMixin) return previousDataStatus;
  return state?.status ?? previousDataStatus;
}
```

This is a **behavioral contract**, not a mandate to copy the example verbatim: respect how the actual `DataStateBuilderWidget` and data cache are wired.

---

## 7. RequestHelper: Provider-Neutral Request Lifecycle

Location (if following the shared architecture):

```text
core/services/base/request_helper.dart
```

The helper should provide reusable request execution and consistent state transitions without knowing which backend produced the result.

### Supported operation patterns

- **Single-value fetch:** `Future<T>` with cache/refresh/reset semantics where applicable.
- **Paginated fetch:** paginated result abstraction with merge, page cursor/params, reset/refresh, and request locks when appropriate.
- **Action/command:** success/failure outcomes, optional success hooks, then an emitted action status.
- **Specialized workflows:** streams, subscriptions, transactions, background sync, or complex multi-step flows may need their own orchestrator rather than forcing everything into a generic helper.

When present, the project may expose methods such as `executeOnce`, `executePaginated`, and `executeAction`. **Inspect actual signatures instead of inventing SDK or helper APIs.**

### Error-result contract (critical)

A successfully awaited `Future<T>` is **not necessarily a successful operation**. If `T` is a result wrapper such as `BackendResult<TData>`, the helper must explicitly handle its failure case. It must not emit `success` simply because a failure result was returned instead of thrown.

Choose the correct helper/adapter for the result contract:

- Throwing `Future<T>`: resolve exceptions to failure.
- Typed `Result`/`BackendResult`: inspect success/failure branches.
- Local cache operations: handle ordinary values or errors without forcing a remote API wrapper.

### Helper rules

- Centralize normal loading/success/failure transitions, error-message conversion, applicable locks, and duplicate-request protection.
- Use `isClosed` checks or equivalent before emitting after asynchronous completion.
- Invoke feature-specific `onSuccess` before publishing a final success state when it changes canonical feature data.
- Preserve current data as appropriate on refresh failures; reset only when explicitly requested.
- Avoid repeated `try/catch`, error parsing, pagination merging, or lifecycle boilerplate in individual Cubits.
- Do not put navigation, toasts, widgets, raw transport clients, or provider-specific queries inside the helper.
- Do not require `RequestHelper` for trivial synchronous state updates.

---

## 8. Centralized Error Handling

Use a shared `ErrorHandler` (or the project's equivalent) to convert expected failures and unexpected exceptions into safe, user-friendly messages.

**Error flow**

```text
Repository outcome / exception
       -> RequestHelper or dedicated orchestrator
       -> centralized ErrorHandler (when mapping is needed)
       -> emitted State(status: failure, message: ...)
       -> Data UI / ActionStateListener according to state category
```

Rules:

1. Reuse SDK-provided safe failure messages (for example `BackendFailure.safeMessage`) when present; do not recreate SDK transport parsing.
2. Keep Cubits and UI independent of HTTP clients, raw Supabase errors, or other provider-specific error formats.
3. A typed failure result must be treated as failure even when no exception is thrown.
4. Catch unexpected exceptions at the correct operation boundary; avoid swallowing errors silently.
5. Data-request failures may render an error/retry view, preserving cached/previous data where appropriate.
6. Action failures use the common action listener for feedback and do not replace page data.
7. Validation messages intended for inline form UI may use ordinary state and `BlocBuilder` instead of a toast.
8. Provide a localized fallback when no safe message exists; never show tokens, stack traces, raw internal errors, or sensitive payloads to users.
9. Do not duplicate identical error conversion or toast logic across Cubits.
10. Keep provider-specific mappings within SDK/DataSource as appropriate. This file defines **state-level handling**, not backend error taxonomies.

---

## 9. Feature State Ownership

The Cubit is the single source of truth for feature business/presentation data, including fetched collections, selected domain items, editable feature forms when applicable, applied filters, sorting and paging state.

- Avoid duplicating a public and private copy of the same mutable data without purpose.
- Expose immutable views or meaningful getters when necessary.
- Do not independently copy canonical feature data into page-local fields without a defined ownership/lifecycle rule.
- Keep cache persistence in the DataSource/Repository; Cubit may hold **in-memory** data for its feature.
- Purely transient visual state (e.g. animation or expansion local to one widget) may remain in the UI when it is not feature business state.

---

## 10. Search, Filtering, Sorting and Pagination

- The Cubit owns applied search/filter/sort criteria and the visible result contract.
- UI forwards input and renders the result; it must not reimplement feature business filtering in builders.
- Keep **draft** filter criteria separate from **applied** criteria. Editing a sheet must not silently change the applied filter before confirmation.
- Re-evaluate applied criteria whenever underlying data changes (fetch, sync, local mutation, or cache restoration).
- Lists, totals, empty states, and pagination should derive from the same visible source.
- Reset or clamp current page when filtering changes the available result range.
- For server pagination, pass criteria through Repository/DataSource; for local pagination, use shared pagination helpers where available.
- Keep account-scoped criteria out of another account's session; reset them when the scope changes.
- Do not create a PaginationManager or infinite scroll machinery for a bounded static list.

---

## 11. Controllers, Initialization, and Lifecycle

### Ownership

Cubit owns controllers and resources that express feature behavior or must be shared across multiple feature widgets (for example form validation, feature search, streams, timers, and coordinated paging).

Widget-local rendering resources may remain in their owning `StatefulWidget` when genuinely local (for example animation controllers or a one-widget expansion controller). **Whatever creates a resource must have an explicit cleanup owner.**

### Initialization

- Prefer one clear, idempotent feature initialization method such as `init()` when several tasks must be coordinated.
- Prevent duplicate initial requests, listeners, subscriptions, and timers when init could be called repeatedly.
- Use explicit refresh/retry/scope-change methods rather than rerunning initialization for every user action.
- Do not create new Cubit instances during a widget rebuild.

### Cleanup

- Override `Cubit.close()` to dispose Cubit-owned controllers and cancel subscriptions/timers.
- A page-scoped Cubit is closed by its provider/owner; do not close a longer-lived shared Cubit when a child page is disposed.
- Use an explicit `resetForScope()` or equivalent for account changes when the Cubit outlives the page.
- Check `isClosed` when async operations may complete after disposal, and avoid work against dead UI contexts.

```dart
@override
Future<void> close() async {
  searchController.dispose();
  await subscription?.cancel();
  return super.close();
}
```

Do not add a confusing generic `dispose()` method to a Cubit just to duplicate `close()`.

---

## 12. Dependency Injection and Feature Scope

- Prefer constructor injection of **Repository contracts** into Cubits.
- Inject applicable DataSource contracts into Repository implementations.
- Register implementations only for the providers actually required by the feature.
- Resolve/construct Cubits at a deliberate feature or route boundary, not repeatedly inside widget `build()`.
- Use existing `BlocProvider`, `BlocProvider.value`, and DI patterns according to ownership. `BlocProvider.value` does not assume ownership of closing an existing Cubit.
- Avoid accessing `ApiClient`, Supabase clients, or `CacheManager` directly from Cubits for feature persistence.
- No mandatory Repository/DataSource for UI-only synchronous state changes.

---

## 13. State Equality and Event Delivery

- States must correctly represent meaningful changes under the project's equality semantics (`Equatable`, records, or other value equality).
- Do not use a non-`const` State solely to force a rebuild.
- Use immutable state payloads when applicable.
- When the same action succeeds twice, both feedback events must be observable. An equal subsequent state may be suppressed by Cubit; ensure transitions or an explicit event revision/ID make distinct completed operations distinguishable.
- An action listener handles **newly emitted** states; it does not replay the Cubit's initial/current state when it first attaches.
- Do not construct States merely to trigger Toasts. Construct and `emit` the intended State.
- Keep UI effects out of `build()` and out of State constructors.

---

## 14. Performance and Rebuild Boundaries

- Scope `BlocBuilder` / `BlocSelector` to widgets that depend on changing values.
- Use `buildWhen` when unrelated action states would otherwise rebuild a data subtree.
- Use **one** stable ActionStateListener per applicable Cubit scope; listeners do not build the UI on each event.
- Avoid duplicate API requests, redundant data transformations, repeated caching writes, and unnecessary emits.
- Prefer memoized/derived visible lists only when computation warrants it; do not duplicate canonical mutable collections.
- Prefer existing shared pagination/search/debounce helpers instead of reimplementing them per feature.
- Do not force every page to use `DataStateBuilderWidget` or `BlocConsumer`. Builders and listeners have distinct responsibilities.

---

## 15. Splitting Cubits and Feature Dependencies

Split Cubits for independent lifecycles, async workflows, feature contracts, or state ownership—not merely because a file became long.

- Extract pure mapping, transformation, or reusable orchestration when it has no independent feature state.
- Avoid child Cubits whose only purpose is reformatting a parent's list.
- Keep Cubit-to-Cubit relationships explicit, acyclic, and minimal; prefer a Repository/shared service where suitable.
- Specify cleanup for subscriptions between Cubits.
- Keep one authoritative owner per mutable feature value.

---

## 16. UI Communication Contract

**UI → Cubit:** public methods and user input.

**Cubit → UI:** immutable State emissions and public read-only feature data/getters.

| UI need | Use |
|---|---|
| Change text, form errors, button loading, or part of a screen | `BlocBuilder` / `BlocSelector` |
| Render data loading/error/empty/success | `DataStateBuilderWidget` when useful |
| Show success/error toast or perform a UI callback after a completed action | `ActionStateListener` |
| Simple local presentation changes independent of business state | Widget-local state when appropriate |

A State's mere possession of `message` does **not** imply automatic toast feedback. Toast behavior requires a concrete `ActionStateMixin` state and an active listener for that Cubit.

---

## 17. AI Coding Rules

AI coding agents MUST:

1. Inspect existing `RequestState`, `ActionStateMixin`, `DataState`, RequestHelper, error handler, and feature Cubit conventions before making changes.
2. Reuse the project's existing base contracts instead of inventing alternative status enums or duplicate response types.
3. Follow `UI -> Cubit -> Repository -> DataSource` for feature data access.
4. Use the shared RequestHelper for conventional async workflows where appropriate, and adapt to its **verified** signatures.
5. Never call a toast/snackbar/navigation method inside a State constructor or as a side effect of a UI builder.
6. Never call `handleActionState()` during construction; only the designated action-feedback listener/handler should invoke it.
7. Place `ActionStateMixin` only on concrete action states.
8. Ensure Action State failures do not drive full-screen data error rendering.
9. Use one action-feedback listener per applicable Cubit scope, never one per action.
10. Preserve `BlocBuilder` behavior for normal UI changes and action-button loading.
11. Treat typed failure results as failures, not successful Futures.
12. Use centralized safe error mapping, not backend-specific parsing inside Cubits.
13. Keep business-critical success processing independent of UI listeners.
14. Ensure correct state equality and distinct delivery of repeated action feedback.
15. Protect asynchronous completion after `close()`, and dispose owned resources.
16. Do not force optional components (cache, pagination, DataStateBuilder, Repository for UI-only work) into unrelated features.
17. Preserve current behavior when refactoring; add or update tests for action success/failure, data preservation, repeated effects, and cleanup.
18. Keep this rule file backend-neutral. Follow specialized SDK/API, Repository/DataSource, Cache, UI, and other provider rules for implementation details.

---

## 18. Migration and Verification Checklist

Use this checklist when updating an existing codebase; do not apply all changes blindly.

- [ ] Move action-feedback execution out of every Action State constructor.
- [ ] Keep `RequestState` field contract and `ActionStateMixin` marker compatible with existing feature states.
- [ ] Introduce a reusable standalone `ActionStateListener` at appropriate feature scopes.
- [ ] Avoid duplicate listeners for the same Cubit instance.
- [ ] Ensure `DataState` ignores Action State **status and error** for page rendering, preserving existing loaded content.
- [ ] Ensure action `loading` can still update affected buttons through `BlocBuilder`.
- [ ] Confirm typed failure results are not treated as `executeOnce` success.
- [ ] Confirm `onDone` is never required for business-critical state updates and `onTap` fires only on a user tap.
- [ ] Verify repeated successful actions produce separate feedback events.
- [ ] Verify Cubit/provider lifecycle: listeners remain mounted where needed; resources close exactly once.
- [ ] Run analyzer/tests and check ordinary data-page loading, action failure, action success, no-message actions, and navigation/disposal scenarios.

---

## 19. Final Philosophy

> Cubits coordinate feature behavior. Repositories and DataSources own data access. RequestHelper centralizes common async lifecycles. States describe results. Builders render UI. One scoped listener handles action feedback—without side effects in State constructors.
