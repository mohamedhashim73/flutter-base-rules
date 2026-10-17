# Refactor Extra Notes (Pending Rules)

> **Status:** staging file — these notes are **NOT** part of the official rules yet.
>
> They capture conventions agreed while refactoring the app's features. They are either
> missing from, or deliberately override, the current rule files. The owner will fold them into the proper rule files
> (`ui_architecture_rules.md`, `cubit_states_architecture.md`,
> `core_widgets_rules.md`, `code_quality_rules.md`) after the full-app refactor.
>
> **How to use:** when refactoring another feature, read this file together with
> `architecture_index.md` and apply every item with rule-level weight.
> **If this file conflicts with a rule file, this file wins** until the rules are updated.
>
> When an item below is merged into a rule file, delete it from here.

---

## 0. Conflicts with current rules (read first)

| Rule file | What it currently says | Do this instead | Why |
|---|---|---|---|
| `ui_architecture_rules.md` §11.4 | shows `final isLoading = state is X && state.status == RequestStatus.loading;` as **good** | expose `cubit.isLoading`; UI reads `cubit.isLoading` | interpreting `state` is logic → belongs to the Cubit |
| `ui_architecture_rules.md` §10.2 | "Use `const` whenever possible" | for spacing prefer `N.vrSpace` / `N.hrSpace` extensions over `const SizedBox(...)` | one shared spacing source of truth (reinforces §16.7) |
| `cubit_states_architecture.md` §4 | shows `const ExampleState({...})` | **never** use `const` for states | two identical `const` states are `==`; `emit` is skipped → no rebuild |
| `cubit_states_architecture.md` §3 | "states are not used for toggles" | form-toggle **values** live in the Cubit; rebuild by reusing a form-changed state | keeps the UI state-free without a new state class per toggle |

---

## 1. UI never owns form / toggle state

- **No `setState`** anywhere in a widget. If something must change, the Cubit emits and
  the widget rebuilds from cubit state.
- **Form submit** (validate + request call) is a Cubit method (e.g. `submit()`),
  not a widget handler.
- **Password visibility** is a Cubit field + method
  (e.g. `obscurePassword`, `togglePasswordVisibility()`), not a `State` field.
- **Derived UI flags** are Cubit getters (e.g. `bool get isLoading`), read directly in the UI.

❌
```dart
// inside the widget State
bool _hidePassword = true;
bool _isLoading = false;

Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);
  await cubit.signIn();
  setState(() => _isLoading = false);
}
```

✅
```dart
// cubit
bool obscurePassword = true;
bool get isLoading =>
    state is SignInState && state.status == RequestStatus.loading;
void togglePasswordVisibility() => emit(SignInFormChangedState());
Future<void> submit() async { /* validate + signIn */ }

// UI
onTap: cubit.submit,
obscureText: cubit.obscurePassword,
isLoading: cubit.isLoading,
```

---

## 2. No unnecessary local variables in the UI

Refines `ui_architecture_rules.md` §11.2 / §11.4:

- used **once** → inline it (no variable)
- reusable **outside** this file → make it an **extension**, not a local
- keep a local **only** if it is used **more than once** in the *same* file **and**
  it is specific to that file
- a `static const` display list inside a widget → promote it to a centralized constant
  (the shared strings / constants class) instead of keeping data as a widget static
- a value **derived inside a `builder`** (a flag computed from a parameter) is not a
  local — it is logic. Expose it as a Cubit getter, or inline the single use. Locals are
  for data already handed over by a Cubit and used **more than once** in the same file.

❌
```dart
final radiusValue = borderRadius ?? BorderRadius.circular(radius!); // used once
final fallback = errorWidget ?? Container(color: AppColors.kSoftGrey);
```

✅
```dart
borderRadius: borderRadius ?? BorderRadius.circular(radius!),
// ...
errorWidget.orFallback(background: background) // extension, reused
```

---

## 3. Reusable value logic → extension

If a piece of logic can be used in more than one place, put it on an extension instead
of a widget getter or a local variable.

Network-image detection on `String?`:
```dart
extension NullableStringExtensions on String? {
  bool get isNetworkImage {
    final value = this;
    return value != null &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }
}
```

Nullable-widget fallback helper:
```dart
extension NullableWidgetExtensions on Widget? {
  Widget orFallback({Color? background}) =>
      this ?? Container(color: background ?? AppColors.kSoftGrey);
}
```

---

## 4. Spacing & padding via extensions

- `Padding(padding: EdgeInsets.only(top: 14))` → `.paddingOnly(top: 14)`
- `Padding(padding: EdgeInsets.symmetric(...))` → `.paddingSymmetric(...)`
- `Padding(padding: EdgeInsets.all(...))` → `.paddingAll(...)`
- `const SizedBox(height: N)` → `N.vrSpace` · `const SizedBox(width: N)` → `N.hrSpace`
- This applies **everywhere**, including inside a `const` tree — drop the `const`
  rather than keep a raw `SizedBox`. Spacing consistency beats the `const`
  micro-optimisation.
- An empty `SizedBox()` placeholder (the `? X : const SizedBox()` fallback) →
  `0.vrSpace` / `0.hrSpace`.
- If the needed spacing extension does not exist, add it to `int_extensions.dart`
  instead of writing the widget by hand.
- Space **around** a widget (a gap above and/or below it) belongs on the widget itself as
  **padding**, not as standalone siblings. Instead of `16.vrSpace, W(), 24.vrSpace` write
  `W().paddingOnly(top: 16, bottom: 24)`. In a vertical list, give each child its own
  padding rather than interleaving `N.vrSpace` rows, so the children list is pure widgets.
  (`.marginOnly` is only for the case where the widget's own decoration/background must
  **not** grow with the space.)
- A wrapper that exists only to pad → drop it and use the extension:
  `Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text(...))` →
  `Text(...).paddingSymmetric(horizontal: 8)`.
- A `Row` / `Column` whose gaps are all the **same** value → use its `spacing:` parameter
  and delete the spacer children:
  `Column(children: [A, 2.vrSpace, B, 2.vrSpace, C])` → `Column(spacing: 2, children: [A, B, C])`.
  `spacing` sits *between* children, so `spacing: 2` with `[A, if (x) B, C]` keeps every gap
  exactly where a spacer would have been.
- `spacing` also covers the "gap between exactly two children" case
  (`Row(children: [A, 10.hrSpace, B])` → `Row(spacing: 10, children: [A, B])`). Do **not**
  keep a hand-written spacer next to a `spacing:` value — the two add up.
- When the gaps genuinely differ (e.g. `16.vrSpace` between the header/table and `12.vrSpace`
  above the footer), prefer making the column uniform with `spacing:` over hand-placed
  spacers; give the odd one out its own padding (`.paddingOnly(bottom: 16)` on a plain
  `Row` / `Column` such as a pagination footer).
- raw `MediaQuery` math → existing `context` extensions

> Overrides §10.2's blanket "use `const`" **for spacing only**; consistent with §7 and §16.7.

---

## 5. No `const` on Cubit states

Do **not** mark state constructors or instances `const`. Two identical `const` states
compare `==`, so a second `emit` is dropped and the UI will not rebuild.
This overrides `cubit_states_architecture.md` §4.

---

## 6. Portrait & landscape share the same widgets

- Portrait and landscape must compose the **same widget instances**. Never define the
  fields / header / title / submit button twice.
- **Landscape is the source of truth.** If the portrait design differs, adopt the
  landscape widget/style for the shared component. Keep a portrait-only wrapper only
  where the surrounding chrome genuinely differs (e.g. scaffold background).
- Shared feature widgets live under the feature `widgets/` folder, one widget class per
  file, each file < 150 lines.

---

## 7. Use the centralized shared widgets

- **Images** → the shared image widget. Never `Image.asset` / `Image.network` /
  `Image.file` / `Image.memory` / `CachedNetworkImage` / `SvgPicture` in feature code
  (`core_widgets_rules.md`).
- **Text inputs** → shared `TxtFieldWidget`. Never `TextField` / `TextFormField`
  (`core_widgets_rules.md`).
- **Do not** create a feature-specific wrapper around a shared widget. Reuse the shared
  widget's own parameters; extend the shared widget only when it truly lacks a needed
  parameter.

---

## 8. When a shared widget / theme may be restyled

- You may update a shared widget or theme to a new style **only if that style is already
  used elsewhere** in the app (so the change stays consistent for everyone).
- Do **not** change a global theme or shared widget just to match one feature's mock.

---

## 9. Cleanup

- Delete dead / fully-commented widget files instead of leaving them in the tree
  (a fully-commented image widget, unused landscape wrappers).

---

## 10. Cubits are created in the page and injected downwards

- A **page** (`lib/views/<feature>/<feature>_page.dart`) is the only place in a feature
  that resolves Cubits from the service locator (`sl<...>()`).
- Subwidgets must **never** call `sl<...>()`. They receive the Cubit(s) they need as
  constructor parameters, and the page passes the same instances down the tree.
- A **Cubit** must not resolve other Cubits with `sl<...>()` either. Take them as
  constructor parameters and wire them in `dependency_injection.dart`
  (`sl.registerLazySingleton<X>(() => X(sl<A>(), sl<B>()))`).
- When a feature has portrait **and** landscape variants, the page owns the Cubits and
  passes them to both. Do not resolve Cubits separately inside each variant.
- One shared instance means one subscription, one source of truth, and widgets that are
  trivially testable (inject a fake Cubit).

❌
```dart
class ExpensesActionsWidget extends StatelessWidget {           // subwidget
  void _open() => sl<ExpensesActionsCubit>().showAddExpenseDialog();
}
```

✅
```dart
// page
final ExpensesActionsCubit _expensesActionsCubit = sl<ExpensesActionsCubit>();
// ... passes it down
ExpensesActionsWidget(expensesActionsCubit: _expensesActionsCubit);

// subwidget
class ExpensesActionsWidget extends StatelessWidget {
  final ExpensesActionsCubit expensesActionsCubit;
  const ExpensesActionsWidget({required this.expensesActionsCubit});
}
```

---

## 11. Business logic lives in the Cubit / model, never in the UI

- Filtering, sorting, mapping, taking a subset, deriving counts/totals — all of it is
  **logic** and belongs to the Cubit (as a getter or method) or the model layer.
- A widget only *renders* what a Cubit getter gives it. A `builder` may contain loop /
  index mechanics, but not `.where(...)`, `..sort(...)` or `.take(n)`.
- Name the exposed member for the domain meaning, not the mechanics (an `active…`
  getter, a `recent…({limit})` method — never `filteredList`).
- Composing a **display model** is logic too. Building a list of display rows (labels,
  formatted values, colours) inside a widget is deriving — expose it as a Cubit getter
  and let the widget only render it. The widget must not decide *what* is shown, only
  *how*.

❌
```dart
final stores = storesCubit.stores.values.where((s) => !s.isDeleted).toList();
final recent = expensesCubit.expenses.values.where((e) => !e.isDeleted).toList()
  ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
final items = recent.take(3).toList();
```

✅
```dart
// cubit
List<StoreModel> get activeStores =>
    _allStores.where((store) => !store.isDeleted).toList();
List<ExpenseModel> recentExpenses({int limit = 3}) { /* filter + sort + take */ }

// UI
final stores = storesCubit.activeStores;
for (final expense in expensesCubit.recentExpenses()) { ... }
```

---

## 12. Data-holding classes belong in `lib/models/`, not `widgets/`

- A class that only holds data has nothing to do with the widget tree. It must not live
  under `widgets/` and must not be named `...Widget`.
- Move it to `lib/models/` as an entity, named `...Model` (a display item, a table page,
  a stat row…).
- Models may import `package:flutter/material.dart` when a field needs a framework type
  (e.g. a `Color`).

---

## 13. Side effects run once, from the page

- Data loading / refresh is triggered **once** from the page (typically `initState` →
  `addPostFrameCallback`), not from each responsive variant.
- Refines `ui_architecture_rules.md` §16.8: the page owns Cubit setup **and** the single
  trigger; portrait/landscape variants only render.

---

## 14. States extend the shared `RequestState`; requests use the helpers

- Every Cubit state class extends `RequestState` (`lib/models/base/request_state.dart`)
  as a `sealed class`. Subclasses pass `super.status` / `super.message`; do **not**
  redeclare `status` / `message` fields per state or mark them `required`.
- One-shot / action states mix in `ActionStateMixin` and call `handleActionState()` in
  the constructor, so toasts live in the shared mixin — not in the state's own
  constructor and not with an ad-hoc `errorMsgIsOn` flag.
- A single request (one document / one call) **and** any action/task flow
  (backup, PDF export, share, delete-and-confirm, …) must go through
  `RequestHelper.execute` instead of a hand-written `emit(loading)` + `try/catch`
  + manual parse. The loading/success/failure transitions (and the failure toast via
  `ActionStateMixin`) are the helper's job; the Cubit only supplies `request`
  (the work) and `onSuccess` (what to do with the result).
- Corollary — **don't call the service directly from the Cubit** when the helper can run
  it: the helper is the one place that owns the query wrapper, the states and the toast,
  which is exactly what keeps the Cubit short and readable. A Cubit that calls
  `FirebaseService...` and `AppToast.showToast(...)` by hand is re-implementing the helper.
- Collection loads / incremental sync go through `IncrementalSyncHelper`; live
  collections through `FirebaseStreamManager`.
- If `onSuccess` needs to read dependencies after the request, pass the resolved value
  out of `request` (return the parsed model / list) and act on `result.data`, rather than
  calling `emit` by hand.

❌
```dart
Future<void> _fetchMyData() async {
  try {
    emit(GetMyDataState(status: RequestStatus.loading));
    final snap = await FirebaseService.getDocument(...);
    if (snap != null && snap.exists && snap.data() != null) {
      final user = UserModel.fromJson(...);
      emit(GetMyDataState(status: RequestStatus.success));
    }
  } on FirebaseException catch (e) {
    emit(GetMyDataState(status: RequestStatus.failure, message: ErrorHandler.error(e: e)));
  } catch (_) {}
}
```

✅
```dart
Future<void> _fetchMyData() async {
  await RequestHelper.execute<GetMyDataState, SingleData<UserModel>, UserModel, Never>(
    emit: emit,
    state: GetMyDataState.new,
    request: ({int? limit}) async { /* fetch + parse → UserModel */ },
    fromResponse: SingleData.new,
    onSuccess: (result) async { /* use result.data */ },
  );
}
```

❌ (task flow that hand-rolls the same transitions)
```dart
Future<void> _submitBackup() async {
  try {
    emit(BackupDataState(status: RequestStatus.loading));
    final json = await FirebaseAdminService.backupAllCollections();
    await _shareBackupFile(json);
    emit(BackupDataState(status: RequestStatus.success));
  } catch (e) {
    emit(BackupDataState(status: RequestStatus.failure, message: ErrorHandler.error(e: e)));
  }
}
```

✅ (task flow through the helper — `request` = the work, `onSuccess` = the rest)
```dart
Future<void> _submitBackup() async {
  await RequestHelper.execute<BackupDataState, SingleData<String>, String, Never>(
    emit: emit,
    state: BackupDataState.new,
    request: ({int? limit}) => FirebaseAdminService.backupAllCollections(),
    fromResponse: SingleData.new,
    onSuccess: (result) async {
      await _shareBackupFile(result.data!);
    },
  );
}
```

Note: the helper runs `onSuccess` **inside** its `try`, so an error thrown there still becomes
a failure state (same coverage as the hand-written `try/catch`).

---

## 15. Prefer `ListView` over `SingleChildScrollView(child: Column(...))`

- A `SingleChildScrollView` whose only child is a `Column` is just a `ListView` with an
  extra layer. Write `ListView(children: [...])` directly.
- `ListView` applies `MediaQuery` padding by default, so **always pass `padding`
  explicitly** — `EdgeInsets.zero` when no extra padding is wanted.
- `ListView` children are already stretched across the cross axis, so
  `crossAxisAlignment: CrossAxisAlignment.stretch` is not needed.
- If a wrapper (e.g. `LandscapeScaffold`) also scrolls the body, turn its scrolling off
  (`scrollable: false`) so the body's `ListView` is the single scroller. Nesting two
  vertical scroll views leaves the inner one with unbounded height.

---

## 16. Project reality notes (this app)

> Unlike the rest of this file, this section names real files and components on purpose —
> it records what *this* app currently does, and what to fix when a feature is touched.
> The rule statements inside still start from the generic rules above/below.

- `cached_network_image` is **not** a dependency, and `cached_network_image_widget.dart`
  was fully commented out. It was replaced with a self-contained `CustomImageWidget`
  (`lib/core/components/custom_image_widget/custom_image_widget.dart`) that handles
  asset + network + error fallback with no new dependency.
- `core_widgets_rules.md` names the shared image widget `MyImage` at `my_image.dart`;
  the app currently implements it as `CustomImageWidget` at `custom_image_widget.dart`.
  Reconcile the naming when the rule is updated.
- `TxtFieldWidget` prefers the **theme** input border over its own `borderRadius`
  parameter (`app_theme.dart` → `AppConstants.kEnabledInputBorder()`, radius 10).
  Matching a design's exact radius/border must be done through the theme, not per field.
- `LandscapeStatStrip` + `LandscapeStatItem`
  (`lib/core/components/landscape_widgets/cards/landscape_stat_strip.dart`) exist but
  **nothing uses them**: dashboard, expenses, payments, inventory, stores and people
  each ship their own copy. Collapse them onto the shared component when touching a
  feature, and delete the per-feature copies + their `...StatItemWidget` data holders
  (they are §12 violations).
- Several features copy-paste landscape table pagination
  (`const _kPageSize`, `int _page`, `sublist`, `addPostFrameCallback(setState)`).
  `setState` is banned (§1), so it moves into the Cubit and hands back a
  `TablePageModel` (`lib/models/table_page_model.dart`).
- **People — still to do (added while splitting the person expenses out of
  `ExpensesCubit`):** `PersonDetailsPage` is a `StatelessWidget`, and its two content widgets
  each resolve their own Cubits with `sl<...>()` (`PeopleCubit`, `PeopleActionsCubit`,
  `ExpensesPersonCubit`, `ExpensesFilterCubit`, `ExpensesActionsCubit`). The page must own
  them and pass them down (§10). The landscape person table also keeps its page in
  `setState` and derives/sorts/totals `personExpenses` in the builder — that logic belongs
  on `ExpensesPersonCubit` with a `TablePageModel` (§11, §16). `landscape_people_body_state.dart`
  and `expenses_actions_cubit`/`people_actions_cubit` still hold similar UI-in-Cubit issues.
  (`ExpensesPersonCubit` itself replaces the person half that used to live on
  `ExpensesCubit`: its own scroll, paging, filter result and `getPersonExpenses()`.)

---

## 17. One `init()` and one `dispose()` per Cubit

- When a Cubit needs several setup steps, do **not** let the page cascade them.
  Group them into a single Cubit method, so the page stays a one-liner and the
  setup order lives with the Cubit.
- Same for teardown: if disposing takes more than one call, add one `dispose()`.
- The page keeps exactly **one call per Cubit**.

❌ page
```dart
void loadAllData() {
  _cubit
    ..initFilterControllers()
    ..initSearchController()
    ..getExpenses();
  _peopleCubit.getPeople();
}

@override
void dispose() {
  _cubit
    ..disposeFilterControllers()
    ..disposeSearchController();
  super.dispose();
}
```

✅ cubit owns the sequence, page stays a one-liner
```dart
// cubit
void init() {
  initFilterControllers();
  initSearchController();
  unawaited(getExpenses());
}

void dispose() {
  disposeFilterControllers();
  disposeSearchController();
}

// page
void loadAllData() {
  _cubit.init();
  _peopleCubit.getPeople();
}

@override
void dispose() {
  _cubit.dispose();
  super.dispose();
}
```

---

## 18. Sheets / dialogs: the Cubit owns the flow, the **UI builds the widget**

- **A Cubit never builds a widget and never imports a widget file.** No
  `showFilterSheet()` that constructs a sheet widget and opens it — that is UI in the
  Cubit. The same goes for the dialog shell (title / `body` / `actions`) or a
  `Widget _buildSaveButton()` helper inside a Cubit: the whole dialog (shell included) is
  a widget file in the feature's `widgets/`, e.g. a `<name>_dialog_widget.dart` building
  `AppDialog(title: isEdit ? 'تعديل المصروف' : 'إضافة مصروف', body: AddExpenseFormWidget(...), actions: [...])`,
  and the UI opens it:
  `onTap: () => showAppDialog(context, SomeDialogWidget(cubit: someCubit, item: item))`.
- What a Cubit **may** call is a core helper that takes *data* and no widget:
  `AppToast.showToast(...)` and `showAppConfirmationDialog(ctx, title:, message:, onConfirm:)`.
  Those are helpers like a service — no widget is constructed in the Cubit.
- A Cubit that already collaborates with another Cubit may expose it with a forwarding
  getter, so the dialog widget takes a single Cubit parameter.
- The show-dialog function takes the UI as a **parameter** and the call site passes the
  widget: `onTap: () => showAppDialog(context, SomeSheetWidget(cubit: someCubit))`.
  (If you prefer the opening to live on the Cubit, it may take the widget as a parameter —
  `void showSheet(Widget sheet)` — but the widget is still built by the caller.)
- There is **no** top-level `void showXDialog(BuildContext, XCubit, {...})` helper in a
  widget file either: call the widget class directly at the call site.
- Everything the sheet **does** is still Cubit logic: **picking** (date / image / …),
  **validating**, **confirming** (apply + close) and **clearing**. A widget handler that
  opens a picker and writes the result back is logic in the UI.
- The form key belongs to the Cubit, created with the other controllers — not a
  `GlobalKey` the widget owns.
- Validate defensively in the Cubit: `if (formKey?.currentState?.validate() == false)
  return;` — **not** `!= true`, so a not-yet-created key never blocks the flow.
- Closing the sheet after a successful apply/clear from the Cubit
  (`AppRoutes.key.currentState?.pop()`) is fine — the action Cubits already do it, and it
  is not widget building.
- The widget keeps only: layout, `BlocBuilder`, `onTap:` wired to a Cubit method, and the
  one line that hands itself to `showAppDialog`.

❌ cubit builds the sheet
```dart
// cubit
void showFilterSheet({bool isPersonFilter = false}) {
  showAppDialog(
    AppRoutes.key.currentContext!,
    ExpenseFilterSheetWidget(cubit: this, isPersonFilter: isPersonFilter),
  );
}
```

❌ cubit builds the dialog *and* its action buttons
```dart
// cubit
void _showExpenseDialog({ExpenseModel? expense}) {
  showAppDialog(
    AppRoutes.key.currentContext!,
    BlocBuilder<ExpensesActionsCubit, ExpensesActionsState>(
      bloc: this,
      builder: (context, state) => AppDialog(
        title: ...,
        body: AddExpenseDialogContentWidget(cubit: this, ...),
        actions: [
          _buildSaveButton(onTap: ...),
          if (isEdit) _buildDeleteButton(expense),
          _buildCancelButton(context),
        ],
      ),
    ),
  );
}

Widget _buildSaveButton({required VoidCallback onTap}) => BtnWidget(...);
```

❌ top-level helper in a widget file
```dart
void showExpenseFilterDialog(BuildContext context, ExpensesCubit cubit, {...}) {
  showAppDialog(context, ExpenseFilterSheetWidget(cubit: cubit, ...));
}
```

✅ cubit owns the flow only — no widget import
```dart
// cubit
Future<void> pickSpecificFilterDate() async {
  final picked = await DateTimePickerService.pickDate(
    initialDate: filterSpecificDate, firstDate: DateTime(2020), lastDate: DateTime(2100),
  );
  if (picked != null) setSpecificDate(picked);
}

void confirmFilterSheet({required bool isPersonFilter}) {
  if (filterFormKey?.currentState?.validate() == false) return;
  final applied = isPersonFilter ? applyPersonFilter() : applyFilter();
  if (!applied) return;
  AppRoutes.key.currentState?.pop();
}
```

✅ UI builds it and passes the widget in
```dart
// widget
FilterIconButtonWidget(
  isActive: filterCubit.isFilterActive,
  onTap: () => showAppDialog(
    context,
    ExpenseFilterSheetWidget(cubit: filterCubit),
  ),
)

// sheet
Form(
  key: cubit.filterFormKey,
  child: ... TxtFieldWidget(
    controller: cubit.specificDateController,
    onTap: () => cubit.pickSpecificFilterDate(),
  ),
)
```

---

## 19. Keep files small — split widgets and split Cubits

- **Widgets.** When a `build` grows long, extract one section per file (a
  `widgets/<section>/<section>_widget.dart` …). Each section widget takes the Cubit it
  reads from. One class per file, and no
  widget-returning helper methods — *those helpers become the new files*.
- **Cubits.** **350 lines is a hard ceiling: the moment a Cubit passes it, split it.**
  Combine everything related to **one concern** into its own Cubit, injected with the data
  Cubit it reads from / writes back to, so the code stays clean and readable. Concerns that
  earn their own Cubit:
  - a list's **filter draft** — controllers, picked values, validation, apply / clear —
    injected with the data Cubit it pushes results into;
  - a **sub-list** of a collection (e.g. one person's items): its own scroll, paging and
    filter result, plus its `get…()` / `clear…()` methods;
  - a **landscape table's page state**: the rows stay on the data Cubit, the child owns the
    page index and the navigation, and it returns to the first page whenever the parent's
    source changes (a load, a sync, a filter, a search).
  Each one stays a single DI line:
  ```dart
  sl.registerLazySingleton<ChildCubit>(() => ChildCubit(sl<DataCubit>()));
  ```
- A **derived** child Cubit (one that only re-shapes the data Cubit's collection) keeps
  itself fresh by subscribing to the parent's stream and reacting to the single state that
  means "data was just applied" — not by the parent pushing into it:
  ```dart
  ExpensesPersonCubit(this._expensesCubit) : super(...) {
    _collectionSubscription = _expensesCubit.stream.listen(_onCollectionChanged);
  }

  void _onCollectionChanged(ExpensesStates state) {
    if (state is GetExpensesState && state.status == RequestStatus.success) {
      _applyPersonExpensesLocalFilter();
    }
  }
  ```
  Cancel the subscription in `close()`. The parent never learns about the child, so the
  child can be added without touching the parent's API.
- The split rule for a filter:
  - the **data Cubit keeps the result** — the applied flag, the filtered items, the
    paginated / table source, and the *mutators* the filter Cubit calls (apply and clear the
    applied criteria). It emits on apply / clear. When a filter can also target a sub-list,
    that sub-list's result lives on the Cubit that owns the sub-list.
  - the **filter Cubit keeps the draft** — controllers, picked dates, the form key,
    validation, pickers, apply / clear logic, the sheet's flow (never the sheet's widget,
    §18), and it emits on input changes.
  - the filter Cubit **forwards** the applied flags so the sheet *and* its toolbar button
    read one Cubit while the truth stays on the Cubit owning the result.
  - both Cubits keep a single `init()` / `dispose()` (§17); the page owns both.
- Page stays ≤ 150 lines.

---

## 20. Comments: few, formal, no decoration

- Comment **only when the code cannot say it itself** — explain *why*, not *what*. If the
  name, the extraction or the type already tells the story, there is no comment.
- **Never write decorative section dividers / banners.** `// ── Search ──`,
  `// Person expenses ─────`, `// ───────`, `// Header ────`, `/* ===== */` …: they carry no
  information, they rot as soon as members move, and a class that seems to need one usually
  needs a **split** (§19) instead.
- Shape: a **doc comment** (`///`) above the member it describes, one or two lines, formal
  prose. Not ASCII art, not an all-caps banner, and above all not a restatement of the
  signature (`/// Incremental sync fetch` above a `get…()` that already says it).
- A rule that is worth keeping goes into this file / the rule files — not into a banner in
  the source.
- Keep what is functional: `// ignore_for_file:` / `// ignore:` directives, `TODO`s, and a
  comment that documents a non-obvious *reason* (a workaround, an ordering constraint).

❌
```dart
// ── Incremental sync fetch ───────
Future<void> getExpenses({bool refresh = false}) async { ... }

// ── Applied filter result (the draft lives on ExpensesFilterCubit) ──
bool _filterApplied = false;
```

✅
```dart
/// The expenses collection: sync, cache, the main list, the applied filter
/// result and the source the landscape table pages through. The filter
/// **draft** lives on `ExpensesFilterCubit`, one person's list on
/// `ExpensesPersonCubit`, the table's page state on `ExpensesTableCubit`.
class ExpensesCubit extends Cubit<ExpensesStates> { ... }
```

---

## 21. Applied-filter results: criteria the owning Cubit re-runs

An applied filter is **not** a list the sheet computed once. It is a criteria **value object**
that the Cubit owning the result keeps, and re-runs itself whenever its data changes:

- The sheet captures the criteria **when the user applies** — never re-reading the live draft
  later. Editing the sheet after applying must not move the applied result.
- **The Cubit that owns the result owns the criteria.** Each list re-runs its own filter —
  the main list's on the data Cubit, a sub-list's on the Cubit that owns that sub-list. No
  Cubit reaches into another to refresh a filter, and no stream listener is needed for it.
- Store the criteria (nullable) instead of a boolean flag: `isFilterActive =>
  appliedCriteria != null` cannot drift out of sync, and clearing the data clears the filter
  by construction.
- **Paging and totalling must read the same source**: the applied result when a filter is on,
  the whole collection otherwise. Mixing them is exactly how a list ends up showing rows the
  total does not count.
- Re-run on **every** data change: load, cache restore, background sync merge, local removal.
  A result recomputed from fresh data has no stale members and drops deleted ones, so nothing
  needs pruning afterwards.
- **The draft is page-scoped.** Whatever the page creates in `init()` it must drop in
  `dispose()` — the picked values included. A draft that outlives the page is how the next
  page's sheet opens pre-filled with another list's filter.
- **`init()` seeds that draft from the filter already applied on the list that page shows**,
  so the sheet opens showing the criteria that are actually filtering it — without ever
  inheriting the *other* filter's or the previous page's draft, and without surviving a
  logout (clearing the data drops the applied criteria). A page that serves two filter modes
  passes its mode to `init()`. Keep a text criterion **as the user typed it** and lower-case
  both sides when matching; storing it pre-lowered is what makes a seeded field come back
  mangled.

✅
```dart
/// The criteria behind the applied filter, `null` while no filter is on.
ExpenseFilterCriteriaModel? _appliedFilter;

bool get isFilterActive => _appliedFilter != null;

/// The source the main list pages through: the applied filter result while a
/// filter is on, the whole collection otherwise.
List<ExpenseModel> get _listSource =>
    _appliedFilter == null ? _allExpenses : _filteredExpenses.values.toList();

/// Re-runs the applied criteria against the current collection, so the result
/// follows every load and never outlives the data behind it.
void _reapplyFilterCriteria() {
  final criteria = _appliedFilter;
  if (criteria == null) return;
  _filteredExpenses = criteria.selectFrom(_allExpenses);
}
```

```dart
// The sheet only captures the draft into a value:
expensesCubit.applyFilteredExpenses(_draftCriteria(withPersonQuery: true));
```

❌
```dart
// A flag that can drift, plus a snapshot pruned by hand after every change:
bool _filterApplied = false;
_filteredExpenses.removeWhere((id, _) => !ids.contains(id));
// …and the page's dispose() kept the picked dates while the sheet was gone.
```

---

## Appendix — already covered by the rules (do NOT re-add when merging)

- Extensions over raw logic → `ui_architecture_rules.md` §7
- Avoid duplicated layout widgets → `ui_architecture_rules.md` §16.7
- `initState` only for cubit init → `ui_architecture_rules.md` §16.8
- Single-use local variables → `ui_architecture_rules.md` §11.2
- Shared image widget → `core_widgets_rules.md` (Image rule)
- Shared text field widget → `core_widgets_rules.md` (Core Text Field Widget Rule)
- Centralized constants / no hardcoded colors & spacing → `architecture_overview.md`
- States must not hold UI / business logic → `cubit_states_architecture.md`
