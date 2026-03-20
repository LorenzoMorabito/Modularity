# Bucket Slot Legend Engine MVP

Engine semantic-first che generalizza il pattern legacy `target + topN + others + legend` in un package shared installabile.

## Binding richiesti

- `Entity Dimension`
- `Value Measure`
- `Ranking Measure`

## Oggetti forniti

- `MOD Bucket Slots`
- `_MOD Bucket Slots Inputs`
- `_MOD Bucket Slots Targets`
- `_MOD Bucket Slots N`
- `_MOD Bucket Slots Slots`
- `_MOD Bucket Slots Legend`

## Uso atteso

Questo package non installa ancora pagine report. Espone il semantic engine che puo essere consumato da bundle successivi per matrix, bar chart, benchmark table o altre viste `target / topN / others`.
