# REST API & Backend SDK Architecture Rules

## 1. Purpose and Scope

This document defines reusable REST API architecture rules for Flutter applications that use `backend_sdk`.

It describes **how an application integrates the SDK**. It does not prescribe a particular backend, business domain, authentication flow, or project-specific API contract.

**In scope:** REST transport integration, SDK configuration, endpoint organization, Remote DataSources, authentication integration when needed, typed results, errors, pagination, multipart operations, logging, and dependency injection.

**Out of scope:** Supabase-specific queries, local persistence implementation, Cubit state patterns, and provider-specific business workflows. Those belong in their respective rules.

### Core principles

- Use `backend_sdk` for REST communication; do not recreate its transport functionality.
- Keep REST requests inside the appropriate **Remote DataSource implementation**.
- Access feature data through **Repository contracts**.
- Keep SDK setup centralized, but create only the configuration a project actually needs.
- Preserve type safety and consistent feature-facing contracts.
- Follow the capabilities and signatures of the **installed SDK version**, not assumptions from a sample project.
- Do not introduce unnecessary layers, wrappers, or provider implementations.

---

## 2. Layer Responsibilities and Data Flow

```text
UI (Page / Widget)
        |
        v
      Cubit
        |
        v
Repository Contract
        |
        v
Repository Implementation
        |
        v
Remote DataSource Contract
        |
        v
REST API DataSource Implementation
        |
        v
backend_sdk (API client)
        |
        v
      REST Server
```

Responses and failures return through the same data layers. The Cubit translates outcomes into states consumed by the UI.

| Layer | Responsibility |
| --- | --- |
| SDK API client | HTTP transport, request execution, and SDK-provided network/session facilities |
| App-wide configuration | Base URL, environment, SDK options, and optional session callbacks |
| Remote DataSource | Provider-specific REST calls, parameters, payloads, and source-level mapping |
| Repository | Coordinate required DataSources, expose models/typed results, and apply data policies |
| Cubit | Feature orchestration, in-memory state, and request lifecycle |
| UI | Rendering, user interaction, and delegation to Cubit |

**Never** call the REST client from a Page, Widget, or Cubit. **Never** place transport logic in a Repository.

For the full contract/implementation rules, see `repository_and_datasource_rules.md`.

---

## 3. SDK Ownership: Reuse Before Implementing

`backend_sdk` is the authoritative REST transport implementation for the project.

Use SDK-supported facilities for the following **when available in the installed version**:

- HTTP operations (GET, POST, PUT, PATCH, DELETE, and other supported methods).
- Query parameters, request bodies, and request options.
- Request/response handling and typed results.
- Multipart and file uploads.
- Shared headers and optional authentication/session integration.
- Error classification and diagnostic information.
- Pagination-related request/response utilities.
- Network logging and other documented transport features.

Rules:

1. Inspect the installed SDK version, its public exports, and existing integration before writing API code.
2. Prefer SDK facilities to handwritten `http`, `Dio`, JSON transport wrappers, or custom clients.
3. Do not add an `ApiServices` facade that merely forwards the SDK's methods.
4. An application-level **configuration/adapter** is permitted when it adds meaningful integration, such as environment selection, token providers, or session callbacks.
5. Do not modify, duplicate, or invent SDK APIs to fit a preferred example.
6. If a capability is missing, assess a supported SDK extension or a narrowly scoped integration rather than creating parallel networking infrastructure.

---

## 4. Application-Level Organization

Illustrative locations (adjust to the project's established structure):

```text
lib/
├── core/
│   ├── network/
│   │   └── endpoints.dart           # Shared REST paths, if needed
│   └── services/
│       ├── base/                    # Reusable SDK configuration utilities, if needed
│       └── domain/                  # App-specific session / integration behavior, if needed
└── view/
    └── {feature}/
        └── data/
            ├── datasource/
            │   ├── {feature}_remote_data_source.dart
            │   └── {feature}_api_data_source.dart
            ├── repository/
            │   ├── {feature}_repository.dart
            │   └── {feature}_repository_impl.dart
            └── models/
```

- The directory tree is **illustrative**, not a requirement to create empty files or directories.
- Use the project's naming conventions and existing dependency injection setup.
- Create an API DataSource **only when a feature actually uses REST**.
- Do not generate Supabase, Cache, or other provider implementations unless they are requested.
- Keep the abstract DataSource contract in its **own file**, and each implementation in a **separate file**.

---

## 5. Centralized SDK Initialization

Configure and share the REST client through the application's composition root / dependency injection setup.

Depending on the project, configuration can include:

- Environment-specific base URL.
- SDK-supported request options and logging configuration.
- Optional shared headers or locale providers.
- Optional authentication token providers and refresh settings.
- Optional callbacks for credential updates or session expiration.

Rules:

- Reuse an appropriately configured client rather than creating one for each request.
- Do not initialize or configure the client inside a Widget, Page, or Cubit.
- Never scatter base URLs or environment selection across features.
- Do not embed credentials, secrets, or environment-specific private keys in source code.
- Use only configuration fields actually supported by the installed SDK version.
- Do not add token/session machinery to projects or endpoints that do not require authentication.
- An SDK wrapper is **optional**, not a mandatory architectural layer.

---

## 6. REST Endpoints

Keep endpoint paths in a predictable, centralized location. A shared endpoint catalog may be split by domain when it grows, without duplicating paths.

Suggested location: `core/network/endpoints.dart` or the equivalent established project location.

Rules:

- Define the API base URL in the shared SDK configuration, not in feature code.
- Prefer named endpoint paths, including parameterized paths where appropriate.
- Do not hardcode REST URLs in Cubits, Pages, or Widgets.
- Keep endpoint definitions independent of UI state and business workflows.
- Avoid duplicating the same paths across multiple DataSources.
- Do not manually assemble full URLs if the SDK handles base URL + path resolution.
- Use backend-specified endpoint names, parameters, and HTTP methods; **do not invent an API contract**.

---

## 7. Remote DataSource Rules

The REST DataSource implementation owns all REST-specific details for the feature.

It may:

- Invoke the SDK's REST client.
- Build source-specific query parameters, request bodies, and multipart payloads.
- Interpret provider-specific payloads or errors.
- Convert response data into feature models or typed outcomes, according to the Repository contract.

It must not:

- Emit Cubit states or handle UI loading/success/failure presentation.
- Navigate, display snackbars, or access Widgets.
- Store feature UI state, controllers, or form keys.
- Decide screen-specific filtering or pagination presentation.
- Reimplement SDK transport, token refresh, or HTTP error classification.

### Contract and implementation

- Define the abstract/abstract-interface contract in a dedicated file.
- Put each concrete REST provider implementation in its own file.
- Inject the configured SDK client via the established DI mechanism.
- Keep the contract independent of the transport where practical.
- If two providers expose equivalent operations, their implementations **may** satisfy the same contract.
- If operations differ, define appropriate independent contracts; do not force unrelated methods into one interface.
- Create only the provider implementations requested for the feature.

Detailed DataSource and Repository naming rules are in `repository_and_datasource_rules.md`.

---

## 8. Repository Boundary

The Repository exposes consistent operations to the Cubit and hides transport details.

- Depend on required DataSource contracts, not concrete REST clients.
- Return feature models or agreed typed results.
- Coordinate multiple sources **only when the feature requires them**.
- Apply cache-first, remote-first, synchronization, refresh, and fallback policies when applicable.
- Convert source-specific results at the appropriate boundary without losing useful failure information.
- Do not execute HTTP methods, construct shared request headers, or perform token refresh directly.
- Do not emit states or trigger navigation.

A REST-only feature may use **one** Remote DataSource. A local or second remote provider must not be added automatically.

---

## 9. SDK Types, Results, and Mapping

Prefer the SDK's exported types **where applicable and supported by the installed version**. Depending on the SDK version, these may include:

- `ApiClient`
- `ApiResponse<T>`
- `BackendResult<T>`
- `PaginationParams`
- `ApiMultipartBody`
- `ApiMultipartFile`

Guidelines:

- Do not duplicate generic SDK response, failure, or pagination wrappers.
- Use typed results instead of spreading raw `dynamic` or unvalidated maps through the application.
- Keep endpoint-specific parsing at the DataSource/model boundary; use the project's model rules.
- Repositories should expose a stable feature-facing contract, even if the transport changes.
- Never parse HTTP response bodies or status codes inside UI components.
- Do not require a raw `ApiResponse` as the return type of every Repository operation.
- Do not force an API-specific wrapper on local operations or non-REST providers.

Always verify generic bounds, method arguments, and result shapes before copying examples from another project.

---

## 10. Authentication and Session Integration (Only If Required)

`backend_sdk` may support attaching authentication and session behavior through configurable providers and callbacks. The **application** owns its authentication policy and persistence.

Possible application responsibilities:

- Provide access/refresh tokens to SDK-supported callbacks.
- Persist updated credentials securely as appropriate.
- Handle account switching, explicit logout, and local user-data cleanup.
- Decide the initial authenticated route and navigation after an expired session.
- Configure an endpoint or provider-specific refresh mechanism when needed and supported.

Rules:

- Centralize authentication integration rather than duplicating it per endpoint.
- Do not inject Authorization headers manually in Cubits or Widgets.
- Do not implement parallel refresh logic when the SDK already supplies the required behavior.
- Let a centralized application session handler decide navigation and clearing user-scoped data.
- Do not assume all backends use refresh tokens, the same expired status codes, or a fixed logout flow.
- Avoid re-entrant expiration or logout handling if callbacks can fire repeatedly.
- Never leave another account's protected data in memory or persisted feature caches after a user switch.

Session callbacks are integration points, **not** permission to put navigation or feature logic inside the SDK transport layer.

---

## 11. Headers and Localization

Use SDK-supported configuration for shared headers and per-request options for genuinely request-specific headers.

- Shared authentication, locale, content type, and agreed backend headers should be defined once.
- The application's active locale must come from its established locale source.
- Header names and formats are determined by the target backend contract.
- Do not repeat standard header construction in every DataSource.
- Do not manipulate common headers in Cubits or Widgets.
- Do not attach credentials where they are not required or authorized.

---

## 12. Pagination (When Required)

Pagination is optional and depends on the endpoint and UI.

- Use SDK-provided pagination request/response types where they match the backend contract.
- Keep HTTP pagination parameter names and request construction in the Remote DataSource.
- Let the Repository expose an agreed paginated result contract.
- Let the Cubit own visible items, current pagination state, and load-more orchestration.
- Avoid duplicate page merges, request locking, or lifecycle logic when existing shared helpers cover them.
- Do not impose page-based pagination on cursor-based or unpaginated APIs.
- Do not require pagination for every GET operation.

For Cubit lifecycle and pagination orchestration, consult `cubit_states_architecture.md`.

---

## 13. Multipart and Uploads (When Required)

- Use SDK-supported multipart/form-data and file abstractions.
- Build endpoint-specific upload parameters in the REST DataSource.
- Support fields and files only as required by the backend endpoint.
- Do not hand-build multipart boundaries or duplicate SDK upload transport.
- Perform feature-specific file validation at the appropriate layer.
- Avoid putting file transport or binary request construction in Cubits or Widgets.
- Do not create upload utilities for features without uploads.

---

## 14. Errors and Typed Failure Handling

Responsibilities:

| Layer | Error responsibility |
| --- | --- |
| SDK | Supported transport failures, network error representation, session integration |
| DataSource | Provider-specific mapping and validation of external response shapes |
| Repository | Consistent feature-level outcomes and applicable fallback decisions |
| Cubit | Request success/failure state, retry orchestration, feature messages |
| UI | Present the state; no HTTP parsing |

Rules:

- Prefer SDK results and failure types rather than duplicating network error parsers.
- Preserve enough context for diagnostics without exposing secrets.
- Do not silently swallow failures or turn unexpected failures into false successes.
- Do not inspect raw HTTP status codes in Pages or Widgets.
- Use app-level error translation only for behavior that the SDK does not already handle.
- Avoid automatic retries for unsafe operations unless the backend semantics and SDK make them safe.

---

## 15. Logging and Security

- Configure network diagnostics centrally using SDK-supported facilities when available.
- Respect development, staging, and production logging policies.
- Avoid duplicate logging at client, DataSource, and Repository layers.
- Do not print access tokens, refresh tokens, passwords, OTPs, session cookies, private identifiers, or sensitive request/response contents.
- Sanitize diagnostic payloads, URLs, and headers before logging.
- Avoid raw `print` statements for networking diagnostics.
- Do not weaken HTTPS/certificate validation in production configuration.
- Keep credentials and environment secrets out of committed source files.

---

## 16. Dependency Injection

Use the application's existing dependency injection strategy.

Recommended dependency graph:

```text
App composition root / DI
    |
    +-- SDK REST client (configured once per required scope)
    |
    +-- REST DataSource implementation
    |       +-- depends on SDK REST client
    |
    +-- Repository implementation
    |       +-- depends on DataSource contract
    |
    +-- Feature Cubit
            +-- depends on Repository contract
```

Rules:

- Prefer constructor injection in DataSources, Repositories, and Cubits.
- Register only the clients and implementations the project requires.
- Keep transport client creation out of business and presentation code.
- Avoid service locators in feature Widgets except at designated composition boundaries allowed by the UI rules.
- Do not make a DataSource stateful or globally singleton merely for convenience.
- When switching REST implementations, change DI wiring rather than Cubit logic where the contracts remain the same.

---

## 17. RequestHelper Is Provider-Neutral

`RequestHelper` is **not** a REST transport component and should not be part of the SDK API client configuration.

- It belongs to shared request/state orchestration, normally under `core/services/base/`.
- Cubits may use it for Repository operations backed by REST, Supabase, local storage, or other asynchronous work.
- It should depend on generic request/result contracts rather than a specific REST response type wherever possible.
- It must not bypass Repository contracts or call `ApiClient` itself.
- Do not require all Repository results to be `ApiResponse` merely to satisfy RequestHelper.
- Keep loading, success, failure, action states, request locks, and pagination lifecycle rules in `cubit_states_architecture.md`.
- Use the project's **actual** RequestHelper interface; do not presume one fixed method name or signature across projects.

---

## 18. Separation From Cache and Other Providers

- Caching policy belongs to the Repository; persistent reads/writes belong to Local DataSources.
- The current local implementation may use `core/network/cache/` (`CacheManager` and `CacheHelper`) where present.
- Future cache facilities in `backend_sdk` should be integrated behind existing contracts when available, without forcing Cubit changes.
- Do not make API client configuration responsible for feature-specific cache keys, expiry, fallback, or synchronization.
- Supabase-specific implementations belong to their own DataSources and follow the relevant repository rules.
- Do not create REST, Supabase, and Cache implementations together by default.
- Firebase is outside the current scope and can be added through separate provider-specific rules later.

References: `repository_and_datasource_rules.md` and `cache_and_local_storage_rules.md`.

---

## 19. Testing and Review Checklist

When adding or changing a REST integration, verify the applicable items:

- The feature depends on a Repository contract, not the API client.
- REST-specific behavior is in a dedicated DataSource implementation.
- SDK client/configuration is reused rather than duplicated.
- Endpoints and environment settings are centralized.
- Request/response mapping matches the **actual** backend contract.
- Auth/session callbacks are correct **if authentication is required**.
- Success, failure, and unexpected-response paths have coverage.
- Pagination, uploads, and retry behavior are tested **if used**.
- Logging excludes sensitive data.
- Tests mock the appropriate DataSource/client boundaries without depending on a live production backend.
- No unused provider, cache, auth, or pagination layers were added.

---

## 20. AI Coding Agent Rules

Before changing a REST feature, an AI agent MUST:

1. Inspect existing project structure, the installed `backend_sdk` exports, and relevant DataSource/Repository code.
2. Read the directly applicable architecture rules rather than all rule files by default.
3. Reuse SDK APIs for network operations; do not invent methods or types.
4. Honor the actual endpoint, authentication, and response contracts of the current backend.
5. Add **only** the required provider implementations.
6. Keep contracts and concrete DataSource implementations in separate files.
7. Keep feature data access behind Repositories and avoid direct client access from Cubits/UI.
8. Keep RequestHelper provider-neutral and owned by the Cubit/state architecture.
9. Avoid unnecessary transport facades, wrappers, duplicated errors, and response types.
10. Preserve existing behavior, error semantics, and session handling during refactoring.
11. Validate changed code with suitable analyzer/tests where available.
12. Never assume that configuration from one project applies to another.

---

## 21. Final Principle

> **`backend_sdk` owns REST transport. DataSources own provider-specific communication. Repositories own data coordination. Cubits own feature orchestration and state. UI owns presentation.**

Apply these boundaries consistently while creating only the functionality each project and feature actually needs.
