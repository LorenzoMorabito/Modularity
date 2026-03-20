# TopN Target Driver Bundle MVP

Bundle semantic-first estratto dal cluster legacy `TopN` + `Dim_Entity` + `SwitchTopByDimension` + `SwitchTopByMesure`.

## Obiettivo

- selezionare una metrica di ranking
- selezionare il grain da ordinare
- opzionalmente fissare un target da mantenere sempre in vista
- esporre misure riusabili per rank, inclusione nel set TopN e highlight del target

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

## Note

Questa prima versione estrae il core semantic del pattern TopN/target. La report UX puo essere aggiunta in una wave successiva senza cambiare il contract di binding.
