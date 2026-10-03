# Project Architecture Map

This project follows a modular architecture based on separated rules files.

---

## Core Architecture Rules
- core_widgets_rules.md
- api_layer_and_services_rules.md

---

## State Management Rules
- cubit_states_architecture.md

---

## Cache and local storage Rules
- cache_and_local_storage_rules.md

---

## Firebase Cost Reduction Rules
- firebase_cost_reduction_rules.md
- Account-boundary cache reset is mandatory: logout/login must clear persisted
  cache and each account-scoped Cubit's in-memory data plus sync marker before
  the next account performs its initial full fetch.
- Incremental sync markers must be persisted separately from large cached
  collection payloads; a no-change sync must never rewrite the full payload.
- Cached `isDeleted` records must be filtered locally before UI exposure; keep
  normal synchronization incremental by `updatedAt` and do not add full reads
  for deletion checks.

---

## UI Architecture Rules
- ui_architecture_rules.md

---

## Shimmer / Skeleton Loading Rules
- shimmer_ui_rules.md

---

## Models & Entities Rules
- models_entities_classes_rules.md
---

## Code quality Rules
- code_quality_rules.md

---

## Overall System Design
- architecture_overview.md

---

## ENTRY RULE (IMPORTANT)
Always start by reading this file first.

This is the single source of truth for the entire project architecture.

Do NOT assume any structure outside what is defined here.

## Github 
- github_commits.md

## Global Skills
- token-efficiency/SKILL.md
