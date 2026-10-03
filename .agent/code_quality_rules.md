`markdown
# Code Quality Rules

---

# 1. Overview

This document defines general code quality and cleanliness rules across the entire project.

These rules apply to:

- UI
- Cubits
- Services
- Models
- Helpers
- Extensions
- Core widgets

The goal is to keep code:

- clean
- minimal
- readable
- predictable
- scalable
- AI-friendly

---

# 2. Default Values Rule

## Core Idea

Do NOT pass parameters with the same value as their default value.

This applies everywhere:

- widgets
- cubit methods
- service methods
- helper methods
- constructors
- utility functions

---

## Forbidden

dart
CustomListviewWidget(
  shrinkWrap: false,
  shimmerShownCondition: false,
  shimmerCount: 6,
  length: items.length,
  itemBuilder: itemBuilder,
)
`

dart
getProducts(
  refresh: false,
)


dart
SomeWidget(
  isEnabled: true,
  padding: EdgeInsets.zero,
)


---

# 3. Correct Usage

dart
CustomListviewWidget(
  length: items.length,
  itemBuilder: itemBuilder,
)


dart
getProducts()


dart
SomeWidget()


---

# 4. When Passing Parameters Is Allowed

Pass a parameter ONLY when:

* it is required
* it changes default behavior
* the value is dynamic
* the value improves readability
* the value is context-specific
* the default behavior must be overridden intentionally

---

# 5. Exception Rule

Passing a default value is allowed only when it improves clarity in a very specific case.

Example:

dart
CustomListviewWidget(
  shrinkWrap: false,
)


This should remain rare.

---

# 6. Why This Rule Exists

Avoiding redundant parameters keeps code:

* shorter
* cleaner
* easier to scan
* easier to maintain
* easier for AI generation
* less noisy
* less repetitive

---

# 7. Forbidden Noise Patterns

dart
padding: EdgeInsets.zero


dart
physics: const AlwaysScrollableScrollPhysics()


dart
isLoading: false


dart
refresh: false


when they already match the default behavior.

---

# 8. Readability Rule

The code should communicate ONLY what changes from the default behavior.

Default behavior should remain implicit.

---

## Good

dart
BtnWidget(
  title: 'Save',
)


---

## Bad

dart
BtnWidget(
  title: 'Save',
  isEnabled: true,
  isLoading: false,
  padding: EdgeInsets.zero,
)


---

# 9. Final Philosophy

> Clean code focuses on meaningful differences only.

Do not pollute code with redundant defaults.

---

# 10. Naming Convention Rules

---

## 10.1 Core Philosophy

Names must be:

* descriptive
* short
* predictable
* intention-revealing

Avoid:

* unnecessary words
* duplicated suffixes
* vague names
* overlong names

---

## 10.2 File Naming Rules

All files must use:

txt
snake_case.dart


---

## 10.3 UI Pages Rule

Pages must end with:

txt
_page.dart


Examples:

txt
login_page.dart
profile_page.dart
products_page.dart


---

## 10.4 UI Widgets Rule

Feature widget files must end with:

txt
_widget.dart


Examples:

txt
login_form_widget.dart
products_grid_widget.dart
profile_header_widget.dart


Do NOT use:

txt
_component.dart


---

## 10.5 Widget Class Naming Rule

Widget classes should:

* use PascalCase
* describe the UI meaning
* always end with `Widget`

Correct:

dart
class LoginFormWidget extends StatelessWidget


dart
class ProductsGridWidget extends StatelessWidget


Wrong:

dart
class LoginForm extends StatelessWidget


dart
class ProductsGridComponent extends StatelessWidget


---

## 10.6 Widget Extraction Rule

Widgets extracted from a page for readability MUST become dedicated widget files.

Do NOT create widget-returning helper methods inside pages.

Wrong:

dart
Widget _buildHeader(BuildContext context)


Correct:

txt
header_widget.dart


dart
class HeaderWidget extends StatelessWidget


---

## 10.7 Cubit Naming Rule

Cubit files must end with:

txt
_cubit.dart


Cubit classes must end with:

txt
Cubit


Correct:

txt
products_cubit.dart


dart
class ProductsCubit extends Cubit<ProductsStates>


---

## 10.8 States Naming Rule

States files must end with:

txt
_states.dart


State classes should end with:

txt
State


Example:

dart
class GetProductsState extends ProductsStates


---

## 10.9 Model Naming Rule

Models must end with:

txt
_model.dart


Classes:

txt
Model


Example:

txt
user_model.dart


dart
class UserModel


---

## 10.10 Service Naming Rule

Services must end with:

txt
_service.dart


Classes:

txt
Service


Example:

txt
firebase_service.dart


dart
class FirebaseService


---

## 10.11 Extension Naming Rule

Extension files must end with:

txt
_extensions.dart


Examples:

txt
build_context_extensions.dart
string_extensions.dart


---

## 10.12 Method Naming Rule

Methods should:

* clearly describe the action
* stay short
* avoid unnecessary wording

Correct:

dart
getProducts()
filterUsers()
completeSignUp()
createOrder()


Wrong:

dart
getProductsFromApiAndUpdateUi()
handleProductsFilteringLogic()


---

## 10.13 Variable Naming Rule

Variables should:

* clearly describe their meaning
* avoid abbreviations
* avoid unnecessary long names

Correct:

dart
products
selectedProduct
isLoading
searchController


Wrong:

dart
prdcts
selectedProductObjectData
isLoadingProductsFromBackend


---

## 10.14 Boolean Naming Rule

Boolean variables should start with:

* is
* has
* can
* should

Examples:

dart
isLoading
hasPermission
canSubmit
shouldRefresh


---

## 10.15 Final Naming Rule

Names should explain intent immediately.

If a name feels repetitive or obvious from context, shorten it.

---

## 10.16 Local Variables Rule

Do NOT create local variables unless they provide a real benefit.

Variables should only exist when they:

* are reused multiple times
* simplify long expressions
* improve readability significantly
* avoid repeated expensive operations
* represent meaningful concepts

If a value is used once:

❌ Don't create a variable.

Prefer direct expressions.

This rule applies to:

* UI
* Cubits
* Services
* Helpers
* Models
* Extensions

---

## 10.17 Unnecessary Spacing Rule

Avoid unnecessary empty lines.

Keep logically related code grouped together.

Empty lines are allowed only when separating:

* different logic sections
* unrelated operations
* lifecycle stages
* large conditional blocks

This applies to every layer.

---

## 10.18 Private vs Public Naming Rule

Avoid creating duplicated references to the same object.

Wrong:

dart
final ProductsCubit productsCubit = sl<ProductsCubit>();
final ProductsCubit _productsCubit = productsCubit;


Wrong:

dart
ProductsResponseModel? products;
ProductsResponseModel? _products;


Correct:

dart
final ProductsCubit _cubit = sl<ProductsCubit>();


or

dart
final ProductsCubit cubit = sl<ProductsCubit>();


Use a single source of truth.

---

## 10.19 Cubit Variable Naming Rule

Cubit references should follow a simple naming style.

Preferred:

dart
final ProductsCubit _cubit = sl<ProductsCubit>();


or

dart
final ProductsCubit cubit = sl<ProductsCubit>();


Avoid:

dart
productsCubit
productsCubitController
productsCubitInstance
productsCubitManager


Keep names short and predictable.

---

## 10.20 One Responsibility Per Variable

Each variable should represent one responsibility only.

Do not create aliases for readability.

Avoid:

dart
final products = cubit.products;


if it is only used once.

Avoid storing the same object under multiple names.

Always keep one source of truth.

---

## 10.21 Constructor Consistency Rule

Prefer `const` constructors whenever possible.

Keep constructor parameters ordered consistently:

1. required parameters
2. optional parameters
3. callbacks

Avoid unnecessary constructor parameters.

This improves readability and keeps AI-generated code consistent.

---

# 11. Design Goal

Following these rules ensures:

* clean code
* predictable naming
* minimal boilerplate
* readable structure
* consistent style
* easier maintenance
* scalable architecture
* AI-friendly code generation



