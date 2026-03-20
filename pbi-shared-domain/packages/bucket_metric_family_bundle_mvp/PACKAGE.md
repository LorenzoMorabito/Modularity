# Bucket Metric Family Bundle MVP

## Identita
- Modulo: `bucket_metric_family_bundle_mvp`
- Dominio: `shared`
- Versione: `0.1.0`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `experimental`
- Compatibilita consumer dichiarata: `shared/any-semantic-model-with-entity-ranking-and-period-family-measures`
- Descrizione: Generic bucket-aware metric family bundle extracted from the legacy sales and promo bucket logic.

## Caratteristiche
- Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.
- Usa binding guidato a ruoli espliciti, cosi ogni parametro ha un significato tecnico chiaro (`guided`).
- Espone una facade table business-facing: `MOD Bucket Family`.

## Cosa installa
- Tabella semantic: `_MOD Bucket Family Inputs`
- Tabella semantic: `_MOD Bucket Family Targets`
- Tabella semantic: `_MOD Bucket Family N`
- Tabella semantic: `_MOD Bucket Family Slots`
- Tabella semantic: `_MOD Bucket Family Legend`
- Tabella semantic: `MOD Bucket Family`
- Tabelle tecniche nascoste dichiarate: `_MOD Bucket Family Inputs`, `_MOD Bucket Family Targets`, `_MOD Bucket Family N`, `_MOD Bucket Family Slots`, `_MOD Bucket Family Legend`
- Tabella facade visibile: `MOD Bucket Family`
- Non installa una report page pronta: il package fornisce solo asset semantic.

## Prerequisiti dichiarati
- Moduli dipendenti: nessuno
- Capability richieste: nessuna
- Core measures richieste: `MOD_BIND_RANKING_MEASURE`, `MOD_BIND_CURRENT_MEASURE`, `MOD_BIND_PREVIOUS_QUARTER_MEASURE`, `MOD_BIND_PREVIOUS_YEAR_MEASURE`, `MOD_BIND_CURRENT_TOTAL_MEASURE`, `MOD_BIND_PREVIOUS_YEAR_TOTAL_MEASURE`
- Core columns richieste: `MOD_BIND_ENTITY_DIMENSION[Value]`

## Parametri di binding

### Entity Dimension
- Binding key: `MOD_BIND_ENTITY_DIMENSION[Value]`
- Tipo: `column`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.entity`
- Default suggerito: `T_DIM_CORPORATION[Corporation]`
- Descrizione: Dimension bucketed into target, TopN competitors, and Others.
- Suggerimenti: `Corporation`, `Company`, `Brand`, `Product`

### Ranking Measure
- Binding key: `MOD_BIND_RANKING_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.ranking`
- Default suggerito: `Sales Values`
- Descrizione: Measure used to rank the entity dimension and define the TopN competitors.
- Suggerimenti: `Sales Values`, `Values`, `Ranking`, `Share`

### Current Measure
- Binding key: `MOD_BIND_CURRENT_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.family.current`
- Default suggerito: `Sales Measure (Bucket, LP)`
- Descrizione: Current-period measure aggregated into target, TopN, and Others buckets.
- Suggerimenti: `Sales Measure (Bucket, LP)`, `Promo Measure (Bucket, LP)`, `ACT`, `Current`

### Previous Quarter Measure
- Binding key: `MOD_BIND_PREVIOUS_QUARTER_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.family.previous-quarter`
- Default suggerito: `Sales Measure (Bucket, PQ)`
- Descrizione: Reference measure used for quarter-over-quarter calculations.
- Suggerimenti: `Sales Measure (Bucket, PQ)`, `Promo Measure (Bucket, PQ)`, `PQ`, `Previous Quarter`

### Previous Year Measure
- Binding key: `MOD_BIND_PREVIOUS_YEAR_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.family.previous-year`
- Default suggerito: `Sales Measure (Bucket, PY)`
- Descrizione: Reference measure used for year-over-year calculations.
- Suggerimenti: `Sales Measure (Bucket, PY)`, `Promo Measure (Bucket, PY)`, `PY`, `Previous Year`

### Current Total Measure
- Binding key: `MOD_BIND_CURRENT_TOTAL_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.family.current-total`
- Default suggerito: `Sales Market Total (LP)`
- Descrizione: Total-market denominator used for current share calculations.
- Suggerimenti: `Sales Market Total (LP)`, `Promo Market Total (LP)`, `Total`, `Denominator`

### Previous Year Total Measure
- Binding key: `MOD_BIND_PREVIOUS_YEAR_TOTAL_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.family.previous-year-total`
- Default suggerito: `Sales Market Total (PY)`
- Descrizione: Total-market denominator used for previous-year share calculations.
- Suggerimenti: `Sales Market Total (PY)`, `Promo Market Total (PY)`, `PY Total`, `Denominator`

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
  -ModuleId bucket_metric_family_bundle_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId bucket_metric_family_bundle_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId bucket_metric_family_bundle_mvp `
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

## File del package
- `manifest.json`: contratto del modulo, binding, output dichiarati e metadati installativi.
- `README.md`: note descrittive, contesto di estrazione o informazioni storiche del package.
- `PACKAGE.md`: scheda installativa locale del package.
- `semantic/`: asset semantic sorgente che il framework materializza nel consumer.