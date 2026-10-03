# Flutter Clean Architecture Rules

A comprehensive set of AI coding rules and architecture guidelines for building Flutter applications. These rules ensure consistent, clean, scalable, and well-structured code when using AI coding assistants.

## How to Use

1. Clone this repository or copy the files into your Flutter project's AI rules directory.
2. Point your AI tool to `architecture_index.md` as the entry point.
3. The AI will follow these rules to generate consistent, architecture-compliant code.

## Architecture Overview

The project follows a strict 3-layer modular architecture:

- **Core** — Services, helpers, and centralized utilities
- **Model** — Data models, entities, and response classes
- **View** — UI layer with Cubit-based state management

**Data Flow:** UI → Cubit → RequestHelper → ApiServices → Server

## Rule Files

| File | Description |
|------|-------------|
| `architecture_index.md` | Master index — always read this first |
| `architecture_overview.md` | Full project architecture and folder structure |
| `api_layer_and_services_rules.md` | API layer, networking, and session management |
| `cubit_states_architecture.md` | Cubit and state management patterns |
| `firebase_architecure_rules.md` | Firebase/Firestore architecture rules |
| `cache_and_local_storage_rules.md` | Caching and offline-first strategies |
| `ui_architecture_rules.md` | UI layer rules and page composition |
| `shimmer_ui_rules.md` | Shimmer/skeleton loading rules for list pages |
| `core_widgets_rules.md` | Reusable widget catalog and conventions |
| `models_entities_classes_rules.md` | Data models, entities, and base contracts |
| `code_quality_rules.md` | Code quality and naming conventions |
| `github_commits.md` | Conventional Commits specification |
| `token-efficiency/SKILL.md` | AI communication efficiency skill |

## Tech Stack

- **State Management:** Cubit (flutter_bloc)
- **Dependency Injection:** GetIt
- **Backend:** Firebase (Firestore)
- **Local Storage:** SharedPreferences
- **Model Parsing:** Playx utilities
- **Commit Standard:** Conventional Commits 1.0.0

## Core Principles

- Strict layer separation — no layer skips another
- Feature isolation — each feature is fully self-contained
- Centralized services, errors, constants, and endpoints
- No raw Flutter primitives — always use core abstractions
- AI-friendly code generation for consistent output
