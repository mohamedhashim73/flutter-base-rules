# Architecture Index

## How to use this index

This file is a routing index, not a request to load every rule file.

Read this index once at the beginning of a new coding task.

Do not read every referenced file automatically. Read a referenced rule file only when its scope applies to the files or feature being changed.

Once a rule file has been read during the current task, treat it as active. Do not reread it unless it changed, the task scope changed, or the context was restarted or compacted.

Before editing any file, read the target file and the directly applicable rule files only.

Do not scan unrelated features or unrelated rule files.

## Project Architecture Map

This project follows a modular architecture based on separated rule files.

## Core Architecture Rules

Read when changing:

- core widgets
- shared components
- API services
- network services
- dependency injection
- shared utilities

Applicable rule files:

- core_widgets_rules.md
- api_layer_and_services_rules.md

## State Management Rules

Read when changing:

- Cubits
- states
- loading or error handling
- pagination
- RequestHelper
- state transitions

Applicable rule file:

- cubit_states_architecture.md

## Repository and Data Source Rules

Read when changing:

- repositories
- data sources
- backend queries
- Firebase queries
- Supabase queries
- data fetching or mapping

Applicable rule file:

- repository_and_datasource_rules.md

## Cache and Local Storage Rules

Read when changing:

- cache services
- SharedPreferences
- local storage
- cache invalidation
- persisted user data
- account switching

Applicable rule file:

- cache_and_local_storage_rules.md

## Firebase Cost Reduction Rules

Read when changing:

- Firebase reads or writes
- Firestore listeners
- synchronization
- incremental sync
- deletion synchronization
- Firebase caching

Applicable rule file:

- firebase_cost_reduction_rules.md

Additional mandatory rules when this scope applies:

- Logout/login must clear persisted cache and each account-scoped Cubit's in-memory data plus its sync marker before the next account performs its initial full fetch.
- Incremental sync markers must be persisted separately from large cached collection payloads.
- A no-change sync must never rewrite the full cached payload.
- Cached `isDeleted` records must be filtered locally before UI exposure.
- Normal synchronization must remain incremental by `updatedAt`.
- Do not add full reads only to check deletions.

## UI Architecture Rules

Read when changing:

- pages
- screens
- widgets
- layouts
- responsive UI
- navigation UI
- RTL or LTR layout
- shared UI components

Applicable rule file:

- ui_architecture_rules.md

## Shimmer and Skeleton Loading Rules

Read when changing:

- loading states
- shimmer widgets
- skeleton screens
- paginated loading UI
- empty or error loading transitions

Applicable rule file:

- shimmer_ui_rules.md

## Models and Entities Rules

Read when changing:

- models
- entities
- JSON serialization
- `fromJson`
- `toJson`
- model fields
- API response mapping

Applicable rule file:

- models_entities_classes_rules.md

## Code Quality Rules

Read when changing:

- formatting
- lint issues
- analyzer issues
- naming
- documentation
- refactoring
- code review fixes

Applicable rule file:

- code_quality_rules.md

## Overall System Design

Read when:

- starting a new feature
- changing the architecture
- adding a new module
- changing communication between layers
- making a cross-feature change
- the task affects multiple architectural layers

Applicable rule file:

- architecture_overview.md

## GitHub and Commits

Read only when the user asks to:

- create a commit
- prepare a commit message
- create a pull request
- review GitHub changes
- inspect branch or PR rules

Applicable rule file:

- github_commits.md

## Global Skills

Read only when the task explicitly requires the related skill or when the current task cannot be completed without it.

Applicable skill:

- token-efficiency/SKILL.md

## Entry Rule

At the beginning of a new coding task:

1. Read this file once.
2. Identify which rule files apply to the requested work.
3. Read only those applicable rule files.
4. Read the target files before editing them.
5. Keep the applicable rules active for the rest of the current task.

Do not reread this file or its rule files for every follow-up request in the same task unless they changed or the context was restarted or compacted.

This file is the source of truth for deciding which architecture rules apply. It does not require loading unrelated rules.