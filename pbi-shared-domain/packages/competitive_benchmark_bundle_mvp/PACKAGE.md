# Competitive Benchmark Bundle MVP

## Identita
- Modulo: `competitive_benchmark_bundle_mvp`
- Dominio: `shared`
- Versione: `0.1.0`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `experimental`
- Rendering strategy: `competitive-benchmark`
- Compatibilita consumer dichiarata: `shared/any-semantic-model-with-benchmark-measures`
- Descrizione: Generic competitive benchmark bundle with scatter presets and benchmark metric selector extracted from the legacy competitive comparison views.

## Caratteristiche
- Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.
- Usa binding guidato a ruoli espliciti, cosi ogni parametro ha un significato tecnico chiaro (`guided`).
- Permette di controllare il perimetro installato scegliendo quante colonne o misure esporre.
- Espone una facade table business-facing: `MOD Competitive Benchmark`.

## Cosa installa
- Tabella semantic: `_MOD Competitive Benchmark Inputs`
- Tabella semantic: `_MOD Competitive Benchmark Metrics`
- Tabella semantic: `_MOD Competitive Benchmark Presets`
- Tabella semantic: `MOD Competitive Benchmark`
- Tabelle tecniche nascoste dichiarate: `_MOD Competitive Benchmark Inputs`, `_MOD Competitive Benchmark Metrics`, `_MOD Competitive Benchmark Presets`
- Tabella facade visibile: `MOD Competitive Benchmark`
- Non installa una report page pronta: il package fornisce solo asset semantic.

## Prerequisiti dichiarati
- Moduli dipendenti: nessuno
- Capability richieste: nessuna
- Core measures richieste: nessuna dichiarata
- Core columns richieste: nessuna dichiarata

## Parametri di binding

### Preset 1 X Measure
- Binding key: `MOD_BIND_PRESET_1_X_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `benchmark.preset.1.x`
- Default suggerito: `Sales Values MS%`
- Descrizione: Measure used on the X axis for benchmark preset 1.
- Suggerimenti: `Sales Values MS%`, `Share`, `X Axis`

### Preset 1 Y Measure
- Binding key: `MOD_BIND_PRESET_1_Y_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `benchmark.preset.1.y`
- Default suggerito: `Promo SOV%`
- Descrizione: Measure used on the Y axis for benchmark preset 1.
- Suggerimenti: `Promo SOV%`, `Growth`, `Y Axis`

### Preset 1 Size Measure
- Binding key: `MOD_BIND_PRESET_1_SIZE_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `benchmark.preset.1.size`
- Default suggerito: `Sales Values`
- Descrizione: Measure used as point size for benchmark preset 1.
- Suggerimenti: `Sales Values`, `Values`, `Size`

### Preset 2 X Measure
- Binding key: `MOD_BIND_PRESET_2_X_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `benchmark.preset.2.x`
- Default suggerito: `Promo ESOV`
- Descrizione: Measure used on the X axis for benchmark preset 2.
- Suggerimenti: `Promo ESOV`, `ESOV`, `X Axis`

### Preset 2 Y Measure
- Binding key: `MOD_BIND_PRESET_2_Y_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `benchmark.preset.2.y`
- Default suggerito: `Sales Values MS%`
- Descrizione: Measure used on the Y axis for benchmark preset 2.
- Suggerimenti: `Sales Values MS%`, `Share`, `Y Axis`

### Preset 2 Size Measure
- Binding key: `MOD_BIND_PRESET_2_SIZE_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `benchmark.preset.2.size`
- Default suggerito: `Sales Values`
- Descrizione: Measure used as point size for benchmark preset 2.
- Suggerimenti: `Sales Values`, `Values`, `Size`

### Preset 3 X Measure
- Binding key: `MOD_BIND_PRESET_3_X_MEASURE`
- Tipo: `measure`
- Obbligatorio: `no`
- Ruolo semantico: `benchmark.preset.3.x`
- Descrizione: Optional X axis measure for benchmark preset 3.
- Suggerimenti: `X Axis`, `Share`, `Index`

### Preset 3 Y Measure
- Binding key: `MOD_BIND_PRESET_3_Y_MEASURE`
- Tipo: `measure`
- Obbligatorio: `no`
- Ruolo semantico: `benchmark.preset.3.y`
- Descrizione: Optional Y axis measure for benchmark preset 3.
- Suggerimenti: `Y Axis`, `Value`, `Rate`

### Preset 3 Size Measure
- Binding key: `MOD_BIND_PRESET_3_SIZE_MEASURE`
- Tipo: `measure`
- Obbligatorio: `no`
- Ruolo semantico: `benchmark.preset.3.size`
- Descrizione: Optional size measure for benchmark preset 3.
- Suggerimenti: `Size`, `Weight`, `Values`

### Preset 4 X Measure
- Binding key: `MOD_BIND_PRESET_4_X_MEASURE`
- Tipo: `measure`
- Obbligatorio: `no`
- Ruolo semantico: `benchmark.preset.4.x`
- Descrizione: Optional X axis measure for benchmark preset 4.
- Suggerimenti: `X Axis`, `Rate`, `Index`

### Preset 4 Y Measure
- Binding key: `MOD_BIND_PRESET_4_Y_MEASURE`
- Tipo: `measure`
- Obbligatorio: `no`
- Ruolo semantico: `benchmark.preset.4.y`
- Descrizione: Optional Y axis measure for benchmark preset 4.
- Suggerimenti: `Y Axis`, `Score`, `Rate`

### Preset 4 Size Measure
- Binding key: `MOD_BIND_PRESET_4_SIZE_MEASURE`
- Tipo: `measure`
- Obbligatorio: `no`
- Ruolo semantico: `benchmark.preset.4.size`
- Descrizione: Optional size measure for benchmark preset 4.
- Suggerimenti: `Size`, `Weight`, `Calls`

### Benchmark Measures
- Collection id: `selector_measures`
- Tipo: `measure`
- Cardinalita: min `1`, max `8`, visibili di default `4`
- Pattern binding: `MOD_BIND_SELECTOR_MEASURE_<n>`
- Descrizione: Choose the benchmark metrics available in the comparison selector.
- Default `Measure 1`: Primary benchmark metric; valore suggerito `Sales Values`; suggerimenti `Sales Values`, `Values`, `Revenue`
- Default `Measure 2`: Secondary benchmark metric; valore suggerito `Sales Units`; suggerimenti `Sales Units`, `Units`, `Volume`
- Default `Measure 3`: Additional benchmark metric; valore suggerito `Promo Spend`; suggerimenti `Promo Spend`, `Spend`, `Investment`
- Default `Measure 4`: Additional benchmark metric; valore suggerito `Promo Contacts`; suggerimenti `Promo Contacts`, `Contacts`, `Calls`
- Default `Measure 5`: Additional benchmark metric; valore suggerito `ACT Mth`; suggerimenti `ACT Mth`, `Actual`, `ACT`
- Default `Measure 6`: Additional benchmark metric; valore suggerito `BDG Mth`; suggerimenti `BDG Mth`, `Budget`, `BDG`
- Default `Measure 7`: Additional benchmark metric; valore suggerito `Previous Year`; suggerimenti `Previous Year`, `PY`, `Prior Year`
- Default `Measure 8`: Additional benchmark metric; valore suggerito `Investments`; suggerimenti `Investments`, `Spend`, `Value`

## Cosa non fa
- Non sostituisce il semantic core del consumer e non deve essere usato per riscrivere asset core fuori dal perimetro modulare.
- Non crea data source, gateway, refresh pipeline o modellazione esterna al package.
- Non deduce automaticamente il significato di business: binding sbagliati producono risultati coerenti tecnicamente ma sbagliati funzionalmente.
- Non include una pagina report pronta: l'authoring report resta in carico al consumer.

## Installazione corretta
- Parametri CLI base: `-ProjectPath`, `-Domain`, `-ModuleId`
- Parametri CLI consigliati per il binding: `-InteractiveUi`, `-SaveBindingProfileAs`, `-BindingProfileId`, `-MappingFile`

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command suggest-bindings `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId competitive_benchmark_bundle_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId competitive_benchmark_bundle_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId competitive_benchmark_bundle_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command test `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH>
```

## Uso consigliato
- Parti dai default o dai suggerimenti automatici e restringi il perimetro solo dopo un primo install riuscito.
- Mantieni nascoste le tabelle tecniche `_MOD ...` e usa la facade table come punto di ingresso per chi costruisce report.
- Riesegui `validate` quando cambi binding e `test` dopo ogni install o upgrade.
- Nelle collection-guided evita di esporre piu dimensioni o misure del necessario: troppi item peggiorano UX e manutenzione.

## File del package
- `manifest.json`: contratto del modulo, binding, output dichiarati e metadati installativi.
- `README.md`: note descrittive, contesto di estrazione o informazioni storiche del package.
- `PACKAGE.md`: scheda installativa locale del package.
- `semantic/`: asset semantic sorgente che il framework materializza nel consumer.