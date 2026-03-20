# Bucketed Overview Matrix Bundle MVP

Versione combinata del cluster `bucketed overview` legacy.

## Obiettivo

Mantenere insieme in un solo package installabile:

- target selector
- TopN selector
- target / TopN / Others
- legend
- dual-family metric outputs
- struttura matrice overview
- report page pronta all'uso

## Oggetti forniti

- `MOD Bucket Overview`
- `_MOD Bucket Overview Inputs`
- `_MOD Bucket Overview Targets`
- `_MOD Bucket Overview N`
- `_MOD Bucket Overview Slots`
- `_MOD Bucket Overview Legend`
- `_MOD Bucket Overview Structure`
- pagina report `Bucketed Overview Matrix`

## Nota

Questo package e la versione "together" del cluster. Le logiche separabili restano comunque disponibili come package piu piccoli:

- `bucket_slot_legend_engine_mvp`
- `bucket_metric_matrix_engine_mvp`
- `bucket_metric_family_bundle_mvp`
