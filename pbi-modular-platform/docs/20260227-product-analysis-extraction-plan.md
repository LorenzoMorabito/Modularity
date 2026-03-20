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
   Status:
   - semantic-first extraction implemented
   - smoke-install validated on sandbox consumer

2. `topn_target_driver_bundle_mvp`
   Combines:
   - target entity selector
   - entity grain switch
   - TopN selector
   - ranking table logic
   Status:
   - semantic-first extraction implemented
   - reusable report page implemented

3. `bucketed_overview_matrix_bundle_mvp`
   Combines:
   - corporation buckets
   - legend slot grouping
   - bucketed LP measures
   - comparison matrix layout logic
   Status:
   - bucket-aware metric family extracted as `bucket_metric_family_bundle_mvp`
   - bucket / legend semantic engine extracted as `bucket_slot_legend_engine_mvp`
   - matrix metric engine extracted as `bucket_metric_matrix_engine_mvp`
   - combined full overview bundle extracted as `bucketed_overview_matrix_bundle_mvp`
   - separate report-only split remains optional if needed later

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

4. `spend_bucket_pareto_mvp`
   Generic Pareto-style spend bucketing extracted from the legacy `GroupBySpending` logic.

5. `kpi_delta_signal_mvp`
   Generic one-measure KPI formatter extracted from the legacy `KpiColorLabel` logic.

### `bucket_slot_legend_engine_mvp`

Derived from:

- `Corporation Buckets`
- `LegendCorp`
- `LegendSlot Groupped (Menarini + TopN + Others)`

Generalization notes:

- the legacy implementation hardcoded a specific target corporation and mixed ranking, slot assignment, and legend aggregation in one block
- the extracted engine keeps the reusable semantics only:
  - selectable target entity
  - configurable TopN size
  - `target / topN / others` slot outputs
  - legend classification and value aggregation
- the target entity is no longer hardcoded and comes from the bound entity dimension
- report matrix layout remains a separate concern for a later bundle

### `bucket_metric_matrix_engine_mvp`

Derived from:

- `ColumnStructure`
- `Msr Sales Buckets LP`
- `Msr Promo Buckets LP`

Generalization notes:

- the legacy matrix mixed column layout metadata and dynamic measure selection in report-specific tables
- the extracted engine keeps the reusable semantic contract:
  - stable matrix column structure
  - group / metric selection metadata
  - dynamic selected value measure
- the primary and secondary measure families are user-bound, so the package is no longer tied to sales and promo naming

### `bucket_metric_family_bundle_mvp`

Derived from:

- `Msr Sales Buckets`
- `Msr Sales Buckets LP`
- `Msr Promo Buckets`
- `Msr Promo Buckets LP`

Generalization notes:

- the legacy logic mixed bucket selection, target handling, and a full metric family in the same tables
- this extracted bundle preserves that combined logic in one reusable semantic package
- the user binds:
  - one entity dimension
  - one ranking measure
  - current / PQ / PY family measures
  - current total / PY total denominators
- the resulting package exposes current value, share, QoQ, YoY, EI, and legend outputs without hardcoding sales or promo naming

### `bucketed_overview_matrix_bundle_mvp`

Derived from:

- `Corporation Buckets`
- `LegendCorp`
- `ColumnStructure`
- `Msr Sales Buckets`
- `Msr Sales Buckets LP`
- `Msr Promo Buckets`
- `Msr Promo Buckets LP`

Generalization notes:

- this is the "keep it together" extraction of the legacy overview cluster
- it combines:
  - target and TopN selectors
  - target / TopN / Others bucketing
  - dual metric families
  - overview matrix column structure
  - legend outputs
  - a reusable report page
- the user binds:
  - one entity dimension
  - one ranking measure
  - a primary current / PQ / PY / total family
  - a secondary current / PQ / PY / total family
- the result is one visible facade table plus an installable report page that can drive a bucketed overview matrix without being tied to sales, promo, or finance naming

### `spend_bucket_pareto_mvp`

Derived from:

- `GroupBySpending`

Generalization notes:

- the legacy object mixed product-specific bucketing and presentation helpers
- the extracted package keeps the reusable semantic logic only:
  - one rankable entity dimension
  - one spend measure
  - derived entity rank
  - cumulative share
  - Top1 / Top2-5 / Top6-10 / Rest bucket outputs
- total spend is derived by removing filters from the bound entity dimension, so the package stays schema-agnostic

### `kpi_delta_signal_mvp`

Derived from:

- `KpiColorLabel`

Generalization notes:

- the legacy table hardcoded one specific YoY measure
- the extracted package binds any delta measure and exposes:
  - formatted arrow label
  - color hex
  - trend class
- this keeps the useful conditional formatting pattern without inheriting the original sales-only naming

## Design Rules For Extracted Packages

- domain must be `shared` for reusable cross-schema logic
- one visible facade table per package
- technical tables prefixed `_MOD `
- no hardcoded table names from the source consumer in business-facing measures
- report assets are optional in first-wave semantic packages when the logic is primarily model-driven

## Residual Legacy Helpers Not Promoted As Standalone Packages

These legacy objects were reviewed but are not being promoted as separate installable packages in the current wave:

- `Dim_Entity`
  The useful target-selection logic is already absorbed into `topn_target_driver_bundle_mvp`.
- `.Titles`
  Most title measures are thin narrative wrappers around selectors that are now better owned inside the report UX of each extracted package.
- `.Colours`
  The reusable part of the pattern is covered by `kpi_delta_signal_mvp`; the remaining color helpers are tightly coupled to package-specific measures.

## Testing Scope

First-wave package validation must include:

- `test-module`
- `test-repo`
- `smoke-install` on a sandbox consumer with explicit mappings
- `test-project` after installation

Second-wave combined bundles should be extracted only after first-wave packages are green and stable.
