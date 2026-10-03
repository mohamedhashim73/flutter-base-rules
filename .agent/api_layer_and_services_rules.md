# API Layer & Network Architecture Rules

This document defines how API calls, session handling, network architecture, and backend communication should be structured across the application.

---

# 1. Core Principle

The API layer is a centralized infrastructure layer.

UI MUST NEVER:

- call APIs directly
- parse raw responses
- manage headers
- handle sessions
- manage tokens
- execute HTTP requests

Cubit is the only layer allowed to communicate with ApiServices.

---

# 2. API Layer Structure

## Core Files

Located inside:

txt
core/
 ├── services/
 │    ├── api_services.dart
 │    ├── request_helper.dart
 │    ├── user_session_service.dart
 │    ├── logging_service.dart
 │
 ├── constants/
 │    ├── endpoints.dart


---

# 3. ApiServices Responsibility

`ApiServices` is the ONLY gateway for HTTP communication.

It is responsible for:

- GET requests
- POST requests
- PUT requests
- PATCH requests
- DELETE requests
- multipart/form-data uploads
- injecting headers
- token handling
- session expiration validation
- logging requests/responses

---

# 4. Forbidden Rules

❌ No `http` usage inside Cubits

❌ No `dio` usage inside Cubits

❌ No raw `Uri.parse()` outside ApiServices

❌ No headers handling outside ApiServices

❌ No token injection manually inside Cubits

❌ No session validation inside UI or Cubits

❌ No duplicated request lifecycle logic inside Cubits

---

# 5. Endpoints Rules

All endpoints MUST be centralized inside:

dart
ApiEndpoints


Example:

dart
ApiEndpoints.login
ApiEndpoints.completeSignUp
ApiEndpoints.products
ApiEndpoints.orderDetails(id)


## Forbidden

❌ Hardcoded URLs inside Cubits

❌ Hardcoded base URLs anywhere else

---

# 6. Standard Request Flow

Request flow must always be:

txt
UI
    ↓
Cubit
    ↓
RequestHelper
    ↓
ApiServices
    ↓
Server


Response flow:

txt
Server
    ↓
ApiServices
    ↓
RequestHelper
    ↓
Cubit
    ↓
State
    ↓
UI


---

# 7. Cubit API Responsibilities

Cubit is responsible for:

- triggering requests
- parsing responses into models
- updating cached data
- emitting states
- request orchestration
- deciding success/failure

Cubit MUST NOT handle:

- HTTP implementation
- headers
- tokens
- session expiration
- duplicated loading/error handling

---

# 8. RequestHelper Rule

All API requests SHOULD be executed through:

dart
RequestHelper.execute(...)


For action requests:

dart
RequestHelper.executeAction(...)


Benefits:

- centralized request lifecycle
- centralized error handling
- reusable pagination
- reusable cache handling
- unified architecture

Only bypass `RequestHelper` when a request has a unique workflow that cannot fit its abstraction.

---

# 9. Do NOT Duplicate Request Flow

Inside Cubits, avoid repeating:

❌ loading state boilerplate

❌ try/catch boilerplate

❌ pagination merge logic

❌ response lifecycle handling

❌ duplicated error parsing

Always reuse `RequestHelper` whenever applicable.

---

# 10. GET Request Pattern

GET requests should support:

- refresh
- reset (if applicable)
- cached data
- pagination (when needed)

Example:

dart
Future<void> getProducts({
  bool refresh = false,
  bool reset = false,
}) async {
  await RequestHelper.execute(
    ...
  );
}


---

# 10.1 Cached Response Rule

Fetched data should remain cached inside the Cubit.

Subsequent requests should rely on:

- refresh
- reset

instead of manually clearing data.

Cached data has higher priority than temporary loading states.

UI should continue rendering existing cached data while refresh requests are executing.

---

# 11. POST / Action Request Pattern

POST requests represent actions such as:

- create
- update
- delete
- authentication
- submit forms

These requests should use:

dart
RequestHelper.executeAction(...)


instead of manually writing request lifecycle code.

Action requests may:

- emit loading
- emit success
- emit failure
- execute success callbacks
- show success/error messages through state handling

---

# 11.1 Multipart / FormData Rules

All uploads MUST go through:

dart
ApiServices.postAsFormData()


Allowed:

- single file upload
- multiple file uploads
- fields + files together

Forbidden:

❌ Multipart implementation outside ApiServices

❌ Direct multipart handling inside Cubits

# 12. Headers Rules

Headers are managed ONLY inside:

dart
ApiServices.getHeaders()


## Responsibilities

Headers automatically inject:

- Authorization token
- Content-Type
- locale
- extra headers

## Forbidden

❌ Manual Authorization headers inside Cubits

❌ Repeated headers logic

---

# 13. Session Management System

Session management is centralized inside:

dart
UserSessionService


---

# 14. UserSessionService Responsibilities

Responsible for:

- reading cached user
- validating session expiration
- logout flow
- clearing cache
- deciding the application's initial route

---

# 15. Session Validation Flow

Every API response MUST trigger:

dart
UserSessionService.validateSessionExpire()


This happens automatically INSIDE `ApiServices`.

Result:

Cubit never handles:

- expired token
- logout navigation
- clearing cache

---

# 16. Main Route Rule

Application startup route must come from:

dart
UserSessionService.kGetMainRoute


Example:

dart
Widget get kGetMainRoute =>
    kCachedUser != null
        ? const HomePage()
        : const SignInPage();


---

# 17. Logging Rules

All request logging is centralized.

Handled ONLY inside:

dart
LoggingService


Every request should log:

- URL
- request method
- headers (when needed)
- request body
- response body
- status code
- execution time

## Forbidden

❌ Logging inside Cubits

❌ Logging inside UI

❌ Random print statements

---

# 18. Error Handling Rules

Errors should be centralized through `RequestHelper` whenever possible.

Cubit should only provide request-specific behavior.

UI MUST NEVER:

- parse responses
- decode json
- inspect status codes

Example:

dart
emit(
  GetProductsState(
    status: RequestStatus.failure,
    message: ErrorHandler.error(error),
  ),
);


---

# 19. RequestStatus Rules

`RequestStatus` is reserved ONLY for asynchronous operations.

Examples:

- API requests
- Firebase requests
- Firebase streams
- uploads
- downloads
- pagination
- refresh
- async actions

## Forbidden Usage

❌ local UI state

❌ selected tabs

❌ selected indexes

❌ filters

❌ search query changes

❌ toggle buttons

❌ simple booleans

---

# 20. Firebase & API Consistency Rule

Firebase architecture follows the SAME philosophy as the API layer.

Both should use:

- centralized services
- Cubit-controlled flow
- state-driven UI
- reusable request helpers
- cached data
- unified request lifecycle

This keeps both architectures predictable and maintainable.

---

# 21. API Orchestration Rule

Request orchestration belongs ONLY to Cubits.

Cubit may coordinate multiple requests when required.

Example:

dart
Future<void> refreshReports() async {
  await getProducts(refresh: true);

  await getProfitReports(refresh: true);
  await getPerformanceReports(refresh: true);
  await getProductsReports(refresh: true);
}


UI should simply call:

dart
cubit.refreshReports();


Never:

❌ call multiple Cubit methods from UI

❌ wait for requests inside UI

❌ chain requests inside widgets

---

# 22. ApiServices Responsibility Rule

`ApiServices` is a transport layer ONLY.

Its responsibility ends after returning the HTTP response.

ApiServices MUST NOT:

❌ parse feature models

❌ contain business logic

❌ trigger Cubit behavior

❌ emit states

❌ coordinate multiple requests

All business behavior belongs to Cubits.

---

# 23. Dependency Injection Rules

Allowed:

dart
final ApiServices api;


or

dart
final ApiServices api = sl<ApiServices>();


inside Cubits and service layer only.

Forbidden:

❌ `sl()` inside UI

❌ ApiServices inside widgets

❌ ApiServices inside feature widgets

---

# 24. Architecture Goal

This architecture ensures:

- centralized networking
- reusable request infrastructure
- reusable RequestHelper
- scalable API layer
- isolated business logic
- centralized session management
- centralized error handling
- consistent caching behavior
- predictable request lifecycle
- cleaner UI
- maintainable Cubits
- AI-friendly project structure