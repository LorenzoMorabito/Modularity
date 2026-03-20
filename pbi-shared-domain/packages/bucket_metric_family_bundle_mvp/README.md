# Bucket Metric Family Bundle MVP

Package semantic-first che generalizza il layer bucket-aware delle famiglie metriche legacy.

## Binding richiesti

- `Entity Dimension`
- `Ranking Measure`
- `Current Measure`
- `Previous Quarter Measure`
- `Previous Year Measure`
- `Current Total Measure`
- `Previous Year Total Measure`

## Oggetti forniti

- `MOD Bucket Family`
- `_MOD Bucket Family Inputs`
- `_MOD Bucket Family Targets`
- `_MOD Bucket Family N`
- `_MOD Bucket Family Slots`
- `_MOD Bucket Family Legend`

## Uso atteso

Questo package espone la family bucket-aware completa:

- target / TopN / Others
- current value
- share
- QoQ%
- YoY%
- EI

Puo essere usato da solo o come layer intermedio per bundle matrix e report overview piu ricchi.
