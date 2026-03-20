# Competitive Benchmark Bundle MVP

Bundle semantic-first estratto dal cluster competitivo del POC legacy:

- `ScatterPreset`
- `SwitchCompetitiveMeasureSelector`
- parte del comportamento di benchmark scatter / trend

## Obiettivo

- configurare preset scatter riusabili
- esporre metriche benchmark selezionabili
- fornire misure semantic per X, Y, Size, label e titolo del benchmark

## Binding

- ruoli guidati per i preset scatter
  - 2 preset obbligatori
  - 2 preset opzionali
- collection `selector_measures`
  metriche rese disponibili nel selettore benchmark

## Output semantic

- tabella visibile: `MOD Competitive Benchmark`
- tabelle tecniche nascoste:
  - `_MOD Competitive Benchmark Inputs`
  - `_MOD Competitive Benchmark Metrics`
  - `_MOD Competitive Benchmark Presets`

## Note

Questa versione estrae il motore semantic del benchmark competitivo. Le pagine report e la UX di focus restano una wave successiva.
