# Bucketed Overview Matrix Bundle MVP

## Identita
- Modulo: `bucketed_overview_matrix_bundle_mvp`
- Dominio: `shared`
- Versione: `0.1.0`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `experimental`
- Compatibilita consumer dichiarata: `shared/any-semantic-model-with-entity-ranking-and-dual-period-family-measures`
- Descrizione: Combined bucketed overview matrix bundle that keeps target, TopN, legend, dual-family matrix logic, and a reusable report page together in one installable package.

## Caratteristiche
- Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.
- Usa binding guidato a ruoli espliciti, cosi ogni parametro ha un significato tecnico chiaro (`guided`).
- Include una report page starter utile per verificare il modulo subito dopo l'installazione.
- Espone una facade table business-facing: `MOD Bucket Overview`.

## Cosa installa
- Tabella semantic: `_MOD Bucket Overview Inputs`
- Tabella semantic: `_MOD Bucket Overview Targets`
- Tabella semantic: `_MOD Bucket Overview N`
- Tabella semantic: `_MOD Bucket Overview Slots`
- Tabella semantic: `_MOD Bucket Overview Legend`
- Tabella semantic: `_MOD Bucket Overview Structure`
- Tabella semantic: `MOD Bucket Overview`
- Tabelle tecniche nascoste dichiarate: `_MOD Bucket Overview Inputs`, `_MOD Bucket Overview Targets`, `_MOD Bucket Overview N`, `_MOD Bucket Overview Slots`, `_MOD Bucket Overview Legend`, `_MOD Bucket Overview Structure`
- Tabella facade visibile: `MOD Bucket Overview`
- Report page: `Bucketed Overview Matrix` (`a5b47dc9f3e84c0f9b10`)

## Prerequisiti dichiarati
- Moduli dipendenti: nessuno
- Capability richieste: nessuna
- Core measures richieste: `MOD_BIND_RANKING_MEASURE`, `MOD_BIND_PRIMARY_CURRENT_MEASURE`, `MOD_BIND_PRIMARY_PREVIOUS_QUARTER_MEASURE`, `MOD_BIND_PRIMARY_PREVIOUS_YEAR_MEASURE`, `MOD_BIND_PRIMARY_CURRENT_TOTAL_MEASURE`, `MOD_BIND_PRIMARY_PREVIOUS_YEAR_TOTAL_MEASURE`, `MOD_BIND_SECONDARY_CURRENT_MEASURE`, `MOD_BIND_SECONDARY_PREVIOUS_QUARTER_MEASURE`, `MOD_BIND_SECONDARY_PREVIOUS_YEAR_MEASURE`, `MOD_BIND_SECONDARY_CURRENT_TOTAL_MEASURE`, `MOD_BIND_SECONDARY_PREVIOUS_YEAR_TOTAL_MEASURE`
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

### Primary Current Measure
- Binding key: `MOD_BIND_PRIMARY_CURRENT_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.overview.primary.current`
- Default suggerito: `Sales Measure (Bucket, LP)`
- Descrizione: Current-period measure for the primary overview family.
- Suggerimenti: `Sales Measure (Bucket, LP)`, `ACT`, `Current`, `Primary`

### Primary Previous Quarter Measure
- Binding key: `MOD_BIND_PRIMARY_PREVIOUS_QUARTER_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.overview.primary.previous-quarter`
- Default suggerito: `Sales Measure (Bucket, PQ)`
- Descrizione: Previous-quarter reference for the primary overview family.
- Suggerimenti: `Sales Measure (Bucket, PQ)`, `PQ`, `Previous Quarter`

### Primary Previous Year Measure
- Binding key: `MOD_BIND_PRIMARY_PREVIOUS_YEAR_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.overview.primary.previous-year`
- Default suggerito: `Sales Measure (Bucket, PY)`
- Descrizione: Previous-year reference for the primary overview family.
- Suggerimenti: `Sales Measure (Bucket, PY)`, `PY`, `Previous Year`

### Primary Current Total Measure
- Binding key: `MOD_BIND_PRIMARY_CURRENT_TOTAL_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.overview.primary.current-total`
- Default suggerito: `Sales Market Total (LP)`
- Descrizione: Current total-market denominator for the primary overview family.
- Suggerimenti: `Sales Market Total (LP)`, `Total`, `Primary Total`

### Primary Previous Year Total Measure
- Binding key: `MOD_BIND_PRIMARY_PREVIOUS_YEAR_TOTAL_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.overview.primary.previous-year-total`
- Default suggerito: `Sales Market Total (PY)`
- Descrizione: Previous-year total-market denominator for the primary overview family.
- Suggerimenti: `Sales Market Total (PY)`, `PY Total`, `Primary Total`

### Secondary Current Measure
- Binding key: `MOD_BIND_SECONDARY_CURRENT_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.overview.secondary.current`
- Default suggerito: `Promo Measure (Bucket, LP)`
- Descrizione: Current-period measure for the secondary overview family.
- Suggerimenti: `Promo Measure (Bucket, LP)`, `ACT`, `Current`, `Secondary`

### Secondary Previous Quarter Measure
- Binding key: `MOD_BIND_SECONDARY_PREVIOUS_QUARTER_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.overview.secondary.previous-quarter`
- Default suggerito: `Promo Measure (Bucket, PQ)`
- Descrizione: Previous-quarter reference for the secondary overview family.
- Suggerimenti: `Promo Measure (Bucket, PQ)`, `PQ`, `Previous Quarter`

### Secondary Previous Year Measure
- Binding key: `MOD_BIND_SECONDARY_PREVIOUS_YEAR_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.overview.secondary.previous-year`
- Default suggerito: `Promo Measure (Bucket, PY)`
- Descrizione: Previous-year reference for the secondary overview family.
- Suggerimenti: `Promo Measure (Bucket, PY)`, `PY`, `Previous Year`

### Secondary Current Total Measure
- Binding key: `MOD_BIND_SECONDARY_CURRENT_TOTAL_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.overview.secondary.current-total`
- Default suggerito: `Promo Market Total (LP)`
- Descrizione: Current total-market denominator for the secondary overview family.
- Suggerimenti: `Promo Market Total (LP)`, `Total`, `Secondary Total`

### Secondary Previous Year Total Measure
- Binding key: `MOD_BIND_SECONDARY_PREVIOUS_YEAR_TOTAL_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.overview.secondary.previous-year-total`
- Default suggerito: `Promo Market Total (PY)`
- Descrizione: Previous-year total-market denominator for the secondary overview family.
- Suggerimenti: `Promo Market Total (PY)`, `PY Total`, `Secondary Total`

## Cosa non fa
- Non sostituisce il semantic core del consumer e non deve essere usato per riscrivere asset core fuori dal perimetro modulare.
- Non crea data source, gateway, refresh pipeline o modellazione esterna al package.
- Non deduce automaticamente il significato di business: binding sbagliati producono risultati coerenti tecnicamente ma sbagliati funzionalmente.
- La pagina report installata e un punto di partenza tecnico, non un report finale pronto per la distribuzione utente.

## Installazione corretta
- Parametri CLI base: `-ProjectPath`, `-Domain`, `-ModuleId`
- Parametri CLI consigliati per il binding: `-InteractiveUi`, `-SaveBindingProfileAs`, `-BindingProfileId`, `-MappingFile`
- Parametro opzionale utile: `-ActivateInstalledPage` per aprire la pagina appena installata come pagina attiva.

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command suggest-bindings `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId bucketed_overview_matrix_bundle_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId bucketed_overview_matrix_bundle_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId bucketed_overview_matrix_bundle_mvp `
  -BindingProfileId <PROFILE_ID>
  -ActivateInstalledPage
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
- Se il package installa una pagina report, usala per smoke test funzionale ma non trattarla come template definitivo di business.

## File del package
- `manifest.json`: contratto del modulo, binding, output dichiarati e metadati installativi.
- `README.md`: note descrittive, contesto di estrazione o informazioni storiche del package.
- `PACKAGE.md`: scheda installativa locale del package.
- `semantic/`: asset semantic sorgente che il framework materializza nel consumer.
- `report/`: eventuali page e visual asset installati nel report consumer.