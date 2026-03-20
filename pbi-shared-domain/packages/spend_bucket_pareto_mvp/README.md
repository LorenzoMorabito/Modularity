# Spend Bucket Pareto MVP

Micro-package estratto dal blocco legacy `GroupBySpending`.

## Obiettivo

- classificare una dimensione rankable in bucket Pareto
- esporre rank, cumulative share e bucket per singola entita
- esporre valore e quota per i bucket `Top1`, `Top2-5`, `Top6-10`, `Rest`

## Bindings

- `MOD_BIND_ENTITY_DIMENSION[Value]`
- `MOD_BIND_SPEND_MEASURE`

## Output semantic

- tabella visibile: `MOD Spend Buckets`
- tabella tecnica nascosta: `_MOD Spend Buckets`

## Note

Il totale viene derivato con `REMOVEFILTERS` sulla dimensione bindata, quindi il package non richiede una misura separata di total market.
