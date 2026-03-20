# TopN Target Driver Bundle MVP

Bundle estratto dal cluster legacy `TopN` + `Dim_Entity` + `SwitchTopByDimension` + `SwitchTopByMesure`, con semantic model e report UX riusabile.

## Obiettivo

- selezionare una metrica di ranking
- selezionare il grain da ordinare
- opzionalmente fissare un target da mantenere sempre in vista
- esporre misure riusabili per rank, inclusione nel set TopN e highlight del target
- installare una pagina report pronta con slicer e driver table

## Binding

- collection `dimensions`
  colonne candidabili come grain di ranking e come target entity
- collection `measures`
  metriche disponibili per il ranking

## Output semantic

- tabella visibile: `MOD TopN Driver`
- tabelle tecniche nascoste:
  - `_MOD TopN Driver Inputs`
  - `_MOD TopN Driver Grains`
  - `_MOD TopN Driver Metrics`
  - `_MOD TopN Driver Targets`
  - `_MOD TopN Driver N`

## Output report

- pagina: `TopN Target Driver`
- slicer inclusi:
  - grain
  - ranking metric
  - target entity
  - Top N
- tabella driver filtrata sul set TopN risultante

## Note

Il grain selector e implementato come field-parameter table, quindi il bundle resta generalista e puo cambiare asse senza dipendere dallo schema del consumer.
