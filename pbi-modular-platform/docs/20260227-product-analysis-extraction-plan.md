# 20260227 Product Analysis Extraction Plan

## Objective

Analyze the legacy `20260227_product_analysis_POC` consumer and extract reusable installable packages that preserve the original functional logic while removing hardcoded dependencies on `sales`, `promo`, or `finance` schemas.

The resulting packages must:

- be installable through `modularity`
- respect the package semantic UX standard
- expose user binding instead of fixed schema references
- stay additive and independent from the target consumer structure

## Functional Inventory

The legacy report is functionally organized into these major blocks:

- KPI and trend switching for short-period vs rolling-period comparisons
- TopN and target-driven ranking logic across multiple entity grains
- Competitive scatter and benchmark views driven by preset metric triplets
- Lag / correlation analytics between a driver metric and a response metric
- Bucketed comparison matrices and legend logic
- Styling helper tables and narrative helper content

## Extraction Strategy

### First-wave packages

These packages are sufficiently separable and can be generalized without preserving legacy schema names.

1. `period_compare_switch_mvp`
   Generic period-mode selector that switches between short-horizon and rolling-horizon metric pairs and exposes selected current, selected reference, delta, and delta percent.

2. `metric_switch_selector_mvp`
   Generic measure selector extracted from the legacy sales / promo / competitive switch tables. Exposes selected metric value and selected metric label from a user-bound list of measures.

3. `lag_correlation_explorer_mvp`
   Generic lag and correlation engine with:
   - selectable lag window
   - lagged driver metric
   - response metric
   - best lag / best correlation diagnostics
   - delta correlation variant

### Second-wave combined bundles

These areas are valid package candidates but are still more intertwined at report level. They should first be preserved as bundles and only later split further.

1. `competitive_benchmark_bundle_mvp`
   Combines:
   - competitive measure selector
   - scatter preset engine
   - entity focus selector
   - time trend companion visuals

2. `topn_target_driver_bundle_mvp`
   Combines:
   - target entity selector
   - entity grain switch
   - TopN selector
   - ranking table logic
   Status:
   - semantic-first extraction implemented
   - report UX still pending as a follow-up wave

3. `bucketed_overview_matrix_bundle_mvp`
   Combines:
   - corporation buckets
   - legend slot grouping
   - bucketed LP measures
   - comparison matrix layout logic

## Legacy-to-Package Mapping

### `period_compare_switch_mvp`

Derived from:

- `SwitchPeriodMode`

Generalization notes:

- the original package mixed sales and promo variants in one table
- the extracted package uses a single metric family with four bindings:
  - short current
  - short reference
  - long current
  - long reference

### `metric_switch_selector_mvp`

Derived from:

- `SwitchMeasureSelector (Sales)`
- `SwitchMeasureSelector (Promo)`
- `SwitchCompetitiveMeasureSelector`

Generalization notes:

- the original logic existed in multiple duplicated selector tables
- the extracted package uses a collection-guided binding contract so the user can bind an arbitrary set of measures
- the selected metric logic becomes schema-agnostic and reusable across other packages

### `lag_correlation_explorer_mvp`

Derived from:

- `SwitchLagSelection`
- `Lambda`
- `MaxLag`

Generalization notes:

- the original logic was tied to `Promo Spend` and `Sales Values`
- the extracted package exposes:
  - one driver measure
  - one response measure
  - one period axis column
- lag tables remain technical internal assets

## Design Rules For Extracted Packages

- domain must be `shared` for reusable cross-schema logic
- one visible facade table per package
- technical tables prefixed `_MOD `
- no hardcoded table names from the source consumer in business-facing measures
- report assets are optional in first-wave semantic packages when the logic is primarily model-driven

## Testing Scope

First-wave package validation must include:

- `test-module`
- `test-repo`
- `smoke-install` on a sandbox consumer with explicit mappings
- `test-project` after installation

Second-wave combined bundles should be extracted only after first-wave packages are green and stable.
