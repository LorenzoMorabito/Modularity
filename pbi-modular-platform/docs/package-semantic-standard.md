# Package Semantic Standard

Standard semantic UX dei package installabili del framework `modularity`.

## Obiettivo

Ridurre il rumore nel semantic model tree dei consumer mantenendo tutti gli asset tecnici necessari al funzionamento del package.

Power BI non supporta una cartella nativa che raggruppi piu tabelle dentro il Model explorer. Lo standard del framework usa quindi una **single visible facade table** per package e sposta il resto negli asset tecnici nascosti, con naming tecnico esplicito `_MOD ...`.

## Regole

Per ogni package `semantic`:

- deve esistere **una sola tabella visibile** dichiarata in `manifest.json` sotto `semanticUx.primaryTable`, con naming business-facing del package
- tutte le altre tabelle dichiarate in `provides.semanticTables` devono essere elencate in `semanticUx.hiddenTables` e devono usare il prefisso tecnico `_MOD `
- ogni tabella tecnica nascosta deve dichiarare `isHidden` come proprieta di tabella immediatamente dopo l'header `table ...`
- la tabella visibile deve contenere le misure business-facing del package e non deve usare naming tecnico come `Inputs`, `Selector`, `Axis`, `Measures`, `Metrics`
- quando una tabella visibile contiene piu misure, queste devono essere organizzate con `displayFolder`
- tabelle di supporto come `Inputs`, `Selector`, `Axis`, `Fields`, `Parameters` devono restare tecniche e quindi nascoste

## Contract Manifest

Ogni modulo semantic deve dichiarare:

```json
"semanticUx": {
  "primaryTable": "MOD Example",
  "hiddenTables": [
    "MOD Example Inputs",
    "MOD Example Selector"
  ]
}
```

Il framework valida che:

- `primaryTable` appartenga a `provides.semanticTables`
- `hiddenTables` contenga tutte e sole le altre tabelle dichiarate
- esista quindi una sola tabella visibile per package

## Note di naming

- per i nuovi package la tabella visibile deve usare, quando possibile, il nome facade del modulo, con prefisso `MOD ` ma senza prefisso tecnico `_MOD`
- tutte le tabelle tecniche nascoste devono usare prefisso `_MOD ` per essere immediatamente riconoscibili nel model tree

## Scope dei test

La suite `test-module` verifica:

- coerenza del contract `semanticUx`
- presenza del flag `isHidden` nelle tabelle tecniche statiche
- coerenza delle stesse regole anche sugli asset TMDL renderizzati dinamicamente
