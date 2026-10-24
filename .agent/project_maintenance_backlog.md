# Project Maintenance Backlog

This file records application-specific technical debt and audit findings. It is
not an architecture-rule file and must not be treated as instructions for other
projects.

## Shared Component Consolidation

- Assess the unused landscape statistics components and the feature-specific
  copies in dashboard, expenses, payments, inventory, stores, and people.
  Consolidate them only after confirming the shared component supports the
  required variants, then remove obsolete copies and their associated display
  data classes.

## Table Pagination

- Replace feature-local landscape table paging implementations that keep page
  state with `setState`, manually slice collections, or schedule pagination
  updates after a frame. Move paging criteria and results to the owning Cubit
  and a reusable presentation data contract.

## People Feature

- Make the feature root own the Cubits used by the people details experience
  and pass the existing instances to descendant widgets and responsive layouts.
- Move landscape table paging, filtering, sorting, and totals out of widget
  builders and into the appropriate Cubit or presentation mapper.
- Review remaining UI-oriented logic in the people and expenses action Cubits.

## Theme Consistency

- Review text-field border customization. Preserve theme ownership of shared
  input styling and introduce a variant only when the requirement is reusable
  beyond one feature.
