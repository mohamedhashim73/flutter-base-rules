# Core Scroll Widgets Rules

## File Path

txt
lib/core/components/custom_listview_widgets/custom_listview_widget.dart


---

# Overview

This file contains the centralized repeated-items rendering system for the entire application.

Whenever the UI needs to display repeated data, developers must first check this file before creating any custom implementation.

The widgets in this file are responsible for:

- list rendering
- grid rendering
- horizontal scrolling
- pagination
- shimmer lists
- empty-aware rendering
- loading-more rendering

The goal is to keep all scrolling behavior centralized and consistent across the project.

---

# 1. Available Widgets

| Widget | Use Case |
|---------|----------|
| `CustomListviewWidget` | Normal vertical lists |
| `PaginatedListviewWidget` | Vertical pagination |
| `CustomHorizontalSingleChildScrollWidget` | Horizontal scrolling |
| `PaginatedHorizontalSingleChildScrollWidget` | Horizontal pagination |
| `CustomAlignedGridWidget` | Grid layouts |
| `ShimmerListViewWidget` | Shimmer-only rendering |

---

# 2. Widget Selection Rules

Always choose the widget based on the rendering behavior rather than rebuilding the scroll implementation manually.

---

## 2.1 Normal Vertical Lists

Use:

dart
CustomListviewWidget


For:

- normal lists
- separated lists
- cached lists
- API data
- Firebase data
- local collections

---

## 2.2 Vertical Pagination

Use:

dart
PaginatedListviewWidget


For:

- infinite scrolling
- load more
- API pagination
- Firebase pagination
- cursor-based pagination

The widget already handles:

- scroll controller
- loading-more indicator
- last-item detection

Do not recreate pagination behavior manually.

---

## 2.3 Horizontal Lists

Use:

dart
CustomHorizontalSingleChildScrollWidget


For:

- categories
- cards
- quick actions
- horizontal products
- stories
- tags

---

## 2.4 Horizontal Pagination

Use:

dart
PaginatedHorizontalSingleChildScrollWidget


For horizontally paginated content.

---

## 2.5 Grid Rendering

Use:

dart
CustomAlignedGridWidget


For:

- products
- dashboard cards
- categories
- galleries
- responsive grids

Do not use:

dart
GridView.builder


or

dart
AlignedGridView


directly inside feature widgets.

---

## 2.6 Shimmer Lists

If the whole section is loading placeholders only, use:

dart
ShimmerListViewWidget


instead of manually generating shimmer items.

---

# 3. Decision Table

| Situation | Widget |
|-----------|--------|
| Vertical list | `CustomListviewWidget` |
| Horizontal list | `CustomHorizontalSingleChildScrollWidget` |
| Grid | `CustomAlignedGridWidget` |
| Vertical pagination | `PaginatedListviewWidget` |
| Horizontal pagination | `PaginatedHorizontalSingleChildScrollWidget` |
| Shimmer list | `ShimmerListViewWidget` |

---

# 4. Forbidden Manual Rendering

Do NOT manually implement repeated-item rendering.

Forbidden examples:

dart
ListView.builder(...)


dart
ListView.separated(...)


dart
GridView.builder(...)


dart
AlignedGridView(...)


dart
children: items.map(...)


dart
List.generate(...)


If a suitable core widget already exists, it must be used.

---

# 5. Feature Extraction Rule

Pages should never contain low-level scrolling logic.

Instead of:

txt
Page
 ├── ListView.builder
 ├── GridView.builder
 ├── Pagination
 └── Empty handling


Prefer:

txt
Page
 ├── Header
 ├── Filters
 ├── ItemsSection
 └── Footer


Then let `ItemsSection` internally use the appropriate core scroll widget.

---

# 6. Default Parameters Rule

Do not pass parameters that already match their default values.

Wrong:

dart
CustomListviewWidget(
  shrinkWrap: false,
  shimmerShownCondition: false,
  shimmerCount: 6,
  length: items.length,
)


Correct:

dart
CustomListviewWidget(
  length: items.length,
)


Only pass a parameter when it:

- changes the default behavior
- is required
- is dynamic
- improves readability

---

# 7. Cached Data Rule

These widgets are rendering widgets only.

They must NOT decide:

- loading
- success
- failure
- empty

Those decisions belong to:

- `RequestState`
- `DataStateBuilderWidget`

The list widget simply renders the provided items.

If cached data already exists, the UI should continue rendering the existing list while a refresh is running instead of rebuilding an empty list.

---

# 8. Separation of Responsibilities

The responsibilities are divided as follows:

**Cubit**

- fetches data
- caches data
- updates models
- emits `RequestState`

**DataStateBuilderWidget**

- decides loading/error/empty/success
- handles retry
- keeps cached data visible during refresh

**CustomListviewWidget**

- renders the actual list only

Each layer has a single responsibility.

---

# 9. Final Rule

Before implementing any repeated-items UI, always check:

txt
lib/core/components/custom_listview_widgets/custom_listview_widget.dart


If one of the existing widgets matches the required behavior, it must be used.

Do not recreate scrolling, pagination, shimmer, or grid behavior manually.

# Core Image Widget Rule

## File Path

txt
lib/core/components/custom_image_widget/my_image.dart


---

# Purpose

Use:

dart
MyImage


for **all image rendering** across the application.

This widget is the application's centralized image abstraction layer.

It should be the only place responsible for handling different image sources and image rendering behavior.

---

# Responsibilities

`MyImage` should handle image rendering regardless of the source.

Supported sources include:

- asset images
- network images
- svg images
- memory images
- file images
- placeholders
- fallback images
- future image types

Feature UI should never care about the underlying implementation.

---

# Rule

Never render images directly inside feature code.

Do NOT use:

dart
Image.asset(...)


dart
Image.network(...)


dart
Image.file(...)


dart
Image.memory(...)


dart
CachedNetworkImage(...)


dart
SvgPicture(...)


inside pages or feature widgets.

---

# Why

Centralizing image rendering provides:

- consistent UI
- reusable image behavior
- centralized placeholder handling
- centralized error handling
- easier migration between image packages
- easier caching improvements
- cleaner feature code

---

# Feature Responsibility

Feature widgets should only provide:

- image source
- fit (if needed)
- dimensions (if needed)

Everything else should remain inside `MyImage`.

---

# Final Rule

Before rendering any image, always check:

txt
lib/core/components/custom_image_widget/my_image.dart


and use:

dart
MyImage


instead of creating image widgets manually.

---

# Core Adaptive Dialog Rule

## File Path

txt
lib/core/components/custom_dialogs_widget/adaptive_dialog_widget.dart


---

# Purpose

Use:

dart
showAdaptiveDialogWidget(...)


for all confirmation and adaptive dialogs.

This is the centralized dialog system.

---

# Rule

Do NOT directly use:

dart
showDialog(...)


dart
showCupertinoDialog(...)


dart
AlertDialog(...)


dart
CupertinoAlertDialog(...)


inside feature code.

---

# Responsibilities

The dialog system should centralize:

- platform adaptation
- styling
- spacing
- actions
- animations
- barrier behavior

Feature code should only provide dialog content.

---

# Final Rule

Always use:

dart
showAdaptiveDialogWidget(...)


---

# Core Bottom Sheet Rule

## File Path

txt
lib/core/components/custom_dialogs_widget/bottom_sheet_widget.dart


---

# Purpose

Use:

dart
AppBottomSheetWithChild(...).showAppBottomSheet()


for all bottom sheet presentations.

---

# Rule

Do NOT directly use:

dart
showModalBottomSheet(...)


or manually recreate bottom sheet styling.

---

# Responsibilities

The bottom sheet should centrally handle:

- safe area
- keyboard insets
- drag behavior
- modal behavior
- animations
- padding
- shape
- background

Feature code should only provide:

dart
child:


---

# Final Rule

Always use:

dart
AppBottomSheetWithChild(...).showAppBottomSheet()


---

# Core Toast Rule

## File Path

txt
lib/core/components/custom_dialogs_widget/show_toast.dart


---

# Purpose

Use:

dart
AppToast.showToast(...)


for all lightweight user feedback.

---

# Rule

Do NOT directly use:

dart
SnackBar(...)


dart
ScaffoldMessenger


or custom overlay implementations.

---

# Responsibilities

The toast system should centralize:

- appearance
- positioning
- duplicate prevention
- animations
- auto-dismiss
- success/error/info styles

---

# Preferred Architecture

Toast triggering should preferably happen from:

- Cubits
- States
- centralized side-effect handlers

instead of UI widgets.

---

# Final Rule

Before showing any lightweight feedback, always use:

dart
AppToast.showToast(...)


instead of implementing custom feedback behavior.

`markdown id="gm8xq2"
# Core Button Widgets Rule

## File Path

txt
lib/core/components/btn_widgets/btn_widget.dart


---

# Purpose

Use the core button widgets for **all clickable actions** across the application.

This file is the centralized button abstraction layer.

---

# Available Widgets

| Use Case | Widget |
|----------|--------|
| Standard app button | `BtnWidget` |
| Fully custom child | `CustomBtnWidget` |
| Text-only action | `TextBtnWidget` |
| Icon-only action | `IconBtnWidget` |

---

# Main Button Rule

Use:

dart
BtnWidget


For:

- submit buttons
- confirm buttons
- save buttons
- authentication buttons
- loading buttons
- disabled buttons
- buttons with icons

---

# Custom Button Rule

Use:

dart
CustomBtnWidget


when the entire button UI is custom.

---

# Text Button Rule

Use:

dart
TextBtnWidget


For:

- resend code
- forgot password
- inline actions
- secondary actions

---

# Icon Button Rule

Use:

dart
IconBtnWidget


For:

- back
- close
- delete
- edit
- more
- favorite
- settings

---

# Forbidden

Do NOT directly use:

dart
ElevatedButton(...)


dart
FilledButton(...)


dart
OutlinedButton(...)


dart
TextButton(...)


dart
IconButton(...)


dart
GestureDetector(...)


dart
InkWell(...)


when one of the core button widgets already satisfies the use case.

---

# Responsibilities

Core button widgets should centralize:

- loading
- disabled state
- animations
- colors
- spacing
- typography
- radius
- tap behavior

Feature widgets should only provide:

- callback
- title
- icon
- child (when applicable)

---

# Default Parameters Rule

Do not pass parameters matching their default values.

Only override behavior intentionally.

---

# Final Rule

Always check:

txt
lib/core/components/btn_widgets/btn_widget.dart


before implementing any button.

---

# Core Dropdown Widget Rule

## File Path

txt
lib/core/components/btn_widgets/drop_down_btn_widget.dart


---

# Purpose

Use:

dart
DropDownBtnWidget<T>


for all dropdown fields.

---

# Rule

Never use directly:

dart
DropdownButton(...)


dart
DropdownButtonFormField(...)


or custom dropdown implementations.

---

# Responsibilities

The dropdown widget should centralize:

- styling
- validation
- menu behavior
- labels
- selected value rendering

Feature code should only provide:

- items
- selected value
- onChanged

---

# Final Rule

Always use:

dart
DropDownBtnWidget<T>


---

# Core Text Field Widget Rule

## File Path

txt
lib/core/components/custom_txt_widgets/text_field_widget.dart


---

# Purpose

Use:

dart
TxtFieldWidget


for all standard text inputs.

---

# Rule

Never use directly:

dart
TextField(...)


dart
TextFormField(...)


inside feature code.

---

# Responsibilities

The widget should centralize:

- decoration
- borders
- colors
- validation appearance
- focus behavior
- spacing
- typography

Controllers remain inside Cubits.

Feature UI should only pass the controller.

---

# Final Rule

Always use:

dart
TxtFieldWidget


---

# Core Search Text Field Widget Rule

## File Path

txt
lib/core/components/custom_txt_widgets/search_txt_field_widget.dart


---

# Purpose

Use:

dart
SearchTextFieldWidget


for all search fields.

---

# Responsibilities

The widget should centralize:

- search UI
- clear action
- search icon
- styling
- focus behavior

Search logic belongs to Cubits.

Search controllers also belong to Cubits.

---

# Final Rule

Always use:

dart
SearchTextFieldWidget


instead of building custom search bars.

---

# Core Pin Code Text Field Widget Rule

## File Path

txt
lib/core/components/custom_txt_widgets/pin_code_txt_field_widget.dart


---

# Purpose

Use:

dart
PinCodeTxtFieldWidget


for OTP and PIN code inputs.

---

# Rule

Never use:

dart
PinCodeTextField(...)


or manually build multiple `TextField`s for OTP input.

---

# Responsibilities

This widget should centralize:

- OTP styling
- code length
- spacing
- focus movement
- RTL/LTR behavior
- validation appearance

---

# Final Rule

Always use:

dart
PinCodeTxtFieldWidget


for verification codes and PIN input.
`

# Core Data State Builder Widget Rule

## File Path

txt
lib/core/components/data_state_widgets/data_state_builder_widget.dart


---

# Purpose

Use:

dart
DataStateBuilderWidget


for **all asynchronous data rendering** across the application.

This widget is the centralized presentation layer for every async operation.

It is responsible only for deciding **what UI should be rendered**, while the Cubit remains responsible for **business logic and data fetching**.

---

# Supported Data Sources

This widget should be used with:

- API requests
- Firebase requests
- Firebase streams
- Local cache
- Pagination
- Refresh operations
- Search results
- Filtered results

---

# Responsibilities

`DataStateBuilderWidget` should centralize rendering for:

- loading
- success
- empty
- failure
- retry
- shimmer
- cached data during refresh

Feature widgets should never duplicate these rendering decisions.

---

# Required Architecture

The flow must always be:

txt
Cubit
    ↓
RequestState<T>
    ↓
DataStateBuilderWidget
    ↓
Success / Empty / Error / Loading


UI must never inspect request states manually.

---

# RequestState Rule

The widget must receive a `RequestState<T>` (or the derived state values) instead of manually checking Cubit states.

The Cubit decides the current state.

The widget decides the current UI.

---

# Cached Data Rule

If cached data already exists:

- the previous content should remain visible
- refreshing should not clear the screen
- refreshing should not show the empty view
- refreshing should not flicker between states

Cached data always has higher priority than showing an empty loading screen.

---

# Refresh Rule

Refreshing existing data should display the current content while the Cubit updates it in the background.

The widget should not replace valid content with loading UI unless no previous data exists.

---

# Retry Rule

Retry behavior should be delegated through:

dart
onRetry


Feature widgets should never create their own retry buttons.

---

# Loading Rule

Loading UI should automatically use:

dart
LoadingViewWidget


or a custom shimmer widget when provided.

---

# Empty Rule

Empty UI should automatically use:

dart
EmptyViewWidget


---

# Error Rule

Failure UI should automatically use:

dart
ErrorViewWidget


---

# Forbidden

Do NOT repeat UI logic such as:

dart
if (state.status == RequestStatus.loading)


dart
if (state.status == RequestStatus.failure)


dart
if (items.isEmpty)


dart
if (state is GetProductsState)


inside feature widgets.

All of these belong inside `DataStateBuilderWidget`.

---

# Action State Rule — CRITICAL

Do NOT pass action states (states that call `handleActionState()`) to `DataState` without `ActionStateMixin`.

If an action state (e.g. `ToggleBookmarkState`, `CreateOrderActionState`) fails and does NOT have `ActionStateMixin`, `DataState` will treat the failure as a page-level error and replace the entire page UI with an error widget — even though the page data is still valid.

**The correct pattern:**

1. Any action state class that calls `handleActionState()` must also use `with ActionStateMixin`
2. `DataState` automatically ignores `ActionStateMixin` states for UI rendering
3. Pages can safely pass `state: state` to `DataState` without filtering — as long as all action states follow rule 1

Wrong (action state without mixin — breaks page UI on failure):

dart
class ToggleBookmarkState extends HomeStates {
  ToggleBookmarkState({...}) { handleActionState(); }
}


Right (action state with mixin — page UI is never affected):

dart
class ToggleBookmarkState extends HomeStates with ActionStateMixin {
  ToggleBookmarkState({...}) { handleActionState(); }
}


See `cubit_states_architecture.md` section 14 for the full rule.

---

# Final Rule

If a UI section depends on asynchronous data, always use:

dart
DataStateBuilderWidget


instead of manually switching between loading, success, empty, and failure widgets.

---

# Core Empty View Widget Rule

## File Path

txt
lib/core/components/data_state_widgets/empty_view_widget.dart


---

# Purpose

Use:

dart
EmptyViewWidget


for all empty-data screens.

Do not recreate empty placeholders manually.

---

# Responsibilities

The widget centralizes:

- illustrations
- titles
- descriptions
- spacing
- styling

---

# Preferred Usage

Normally it should be displayed automatically by:

dart
DataStateBuilderWidget


Only use it directly for standalone empty pages.

---

# Final Rule

Always use:

dart
EmptyViewWidget


for empty-state UI.

---

# Core Error View Widget Rule

## File Path

txt
lib/core/components/data_state_widgets/error_view_widget.dart


---

# Purpose

Use:

dart
ErrorViewWidget


for all failure screens.

---

# Responsibilities

The widget centralizes:

- retry button
- illustrations
- messages
- spacing
- styling

---

# Retry Rule

Retry callbacks should be passed into:

dart
ErrorViewWidget


instead of creating custom retry buttons.

---

# Preferred Usage

Normally it should be rendered automatically through:

dart
DataStateBuilderWidget


---

# Final Rule

Always use:

dart
ErrorViewWidget


for failure UI.

---

# Core Loading View Widget Rule

## File Path

txt
lib/core/components/data_state_widgets/loading_view_widget.dart


---

# Purpose

Use:

dart
LoadingViewWidget


for all loading UI.

---

# Responsibilities

The widget centralizes:

- loading indicators
- inline loading
- full-screen loading
- section loading

---

# Button Loading

If a button supports loading internally (such as `BtnWidget`), use that support instead of replacing its child manually.

---

# Preferred Usage

Loading UI should usually be displayed through:

dart
DataStateBuilderWidget


rather than directly.

---

# Final Rule

Always use:

dart
LoadingViewWidget


instead of manually building progress indicators.

---

# Core Shimmer Item Widget Rule

## File Path

txt
lib/core/components/shimmer_widgets/shimmer_item_widget.dart


---

# Purpose

Use:

dart
ShimmerItemWidget


for all shimmer placeholders.

---

# Responsibilities

The widget centralizes:

- shimmer animation
- placeholder appearance
- spacing
- loading skeleton style

---

# Composition Rule

Feature-specific shimmer layouts should compose:

dart
ShimmerItemWidget


instead of recreating shimmer decorations.

For shimmer lists, combine it with:

dart
ShimmerListViewWidget


---

# Final Rule

Always use:

dart
ShimmerItemWidget


as the application's base shimmer component.

---

# Core App Scaffold Widget Rule

## File Path

txt
lib/core/components/others_widgets/custom_scaffold.dart


---

# Purpose

Use:

dart
AppScaffold


as the default scaffold for feature pages.

---

# Responsibilities

`AppScaffold` should centralize:

- Scaffold
- SafeArea
- AppBar integration
- Refresh behavior
- Shared background
- Shared spacing
- Keyboard behavior

---

# Rule

Do not repeatedly wrap feature pages with:

dart
Scaffold


dart
SafeArea


dart
RefreshIndicator


unless the page has a truly custom layout that `AppScaffold` cannot support.

---

# Final Rule

Every standard application page should start with:

dart
AppScaffold


instead of recreating the page structure manually.

# Final Rule

Every standard application page should start with:

dart
AppScaffold


instead of recreating the page structure manually.