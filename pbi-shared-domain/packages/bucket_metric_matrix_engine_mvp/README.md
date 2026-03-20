# Bucket Metric Matrix Engine MVP

Engine semantic-first che generalizza la `ColumnStructure` e lo switch dinamico dei valori della matrix overview legacy.

## Binding richiesti

- 4 misure per la famiglia primaria: `ACT`, `MS%`, `QoQ%`, `YoY%`
- 4 misure per la famiglia secondaria: `ACT`, `MS%`, `QoQ%`, `YoY%`

## Oggetti forniti

- `MOD Bucket Matrix`
- `_MOD Bucket Matrix Structure`

## Uso atteso

Questo package isola la struttura colonne e la misura dinamica della matrix. Va poi combinato con engine come `bucket_slot_legend_engine_mvp` o con un report bundle dedicato per ricreare l'overview completa.
