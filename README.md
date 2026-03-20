# Modularity Area

Questa area raccoglie tutto cio che riguarda l'authoring modulare e la platform condivisa.

## Domini contenuti

- [pbi-finance-domain](./pbi-finance-domain)
  Domain source per i package finance.
- [pbi-marketing-domain](./pbi-marketing-domain)
  Domain source per i package marketing.
- [pbi-shared-domain](./pbi-shared-domain)
  Domain source per i package semantic generalisti e cross-schema.
- [pbi-modular-platform](./pbi-modular-platform)
  Installer, quality checks, schemi e documentazione lifecycle.

## Stato attuale

Package attualmente catalogati:

- finance:
  - `finance_compare_mvp` `0.2.2`
- marketing:
  - `flex_metrics_table_mvp` `0.4.2`
  - `flex_table_flat_mvp` `0.4.2`
- shared:
  - `bucketed_overview_matrix_bundle_mvp` `0.1.0`
  - `bucket_metric_family_bundle_mvp` `0.1.0`
  - `bucket_metric_matrix_engine_mvp` `0.1.0`
  - `bucket_slot_legend_engine_mvp` `0.1.0`
  - `competitive_benchmark_bundle_mvp` `0.1.0`
  - `period_compare_switch_mvp` `0.1.0`
  - `metric_switch_selector_mvp` `0.1.0`
  - `lag_correlation_explorer_mvp` `0.1.0`
  - `spend_bucket_pareto_mvp` `0.1.0`
  - `kpi_delta_signal_mvp` `0.1.0`
  - `topn_target_driver_bundle_mvp` `0.2.0`

Capabilita oggi operative della platform:

- `list-modules`
- `validate-project`
- `install-module`
- `upgrade-module`
- `diff-module`
- `rollback-module`
- `suggest-bindings`
- `list-binding-profiles`
- `set-data-source-path`
- `test-module`
- `test-project`
- `test-repo`
- `smoke-install`
- `Invoke-PbiModularity.ps1` wrapper CLI
- generator `new-module`

## Documentazione package

Ogni package installabile deve esporre una scheda locale `PACKAGE.md` nella propria cartella con:

- funzionalita e limiti del modulo
- binding e parametri richiesti
- asset installati nel consumer
- procedura corretta di validazione, installazione e test

## Regola operativa

- i package source si sviluppano qui
- gli asset installati restano nei consumer sotto `powerbi-projects`
- il contract `core vs module` va rispettato prima di introdurre nuovi oggetti
