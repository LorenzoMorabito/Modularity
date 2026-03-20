# Bucket Metric Matrix Engine MVP

## Identita
- Modulo: `bucket_metric_matrix_engine_mvp`
- Dominio: `shared`
- Versione: `0.1.0`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `experimental`
- Compatibilita consumer dichiarata: `shared/any-semantic-model-with-two-measure-families`
- Descrizione: Generic bucket metric matrix engine extracted from the legacy dynamic overview column structure and measure-switch logic.

## Caratteristiche
- Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.
- Usa binding guidato a ruoli espliciti, cosi ogni parametro ha un significato tecnico chiaro (`guided`).
- Espone una facade table business-facing: `MOD Bucket Matrix`.

## Cosa installa
- Tabella semantic: `_MOD Bucket Matrix Structure`
- Tabella semantic: `MOD Bucket Matrix`
- Tabelle tecniche nascoste dichiarate: `_MOD Bucket Matrix Structure`
- Tabella facade visibile: `MOD Bucket Matrix`
- Non installa una report page pronta: il package fornisce solo asset semantic.

## Prerequisiti dichiarati
- Moduli dipendenti: nessuno
- Capability richieste: nessuna
- Core measures richieste: `MOD_BIND_GROUP_1_ACT_MEASURE`, `MOD_BIND_GROUP_1_SHARE_MEASURE`, `MOD_BIND_GROUP_1_QOQ_MEASURE`, `MOD_BIND_GROUP_1_YOY_MEASURE`, `MOD_BIND_GROUP_2_ACT_MEASURE`, `MOD_BIND_GROUP_2_SHARE_MEASURE`, `MOD_BIND_GROUP_2_QOQ_MEASURE`, `MOD_BIND_GROUP_2_YOY_MEASURE`
- Core columns richieste: nessuna dichiarata

## Parametri di binding

### Primary Group ACT Measure
- Binding key: `MOD_BIND_GROUP_1_ACT_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.matrix.primary.act`
- Default suggerito: `Sales Measure (Bucket, LP)`
- Descrizione: Current-value measure for the primary metric family.
- Suggerimenti: `Sales Measure (Bucket, LP)`, `ACT`, `Current Value`

### Primary Group Share Measure
- Binding key: `MOD_BIND_GROUP_1_SHARE_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.matrix.primary.share`
- Default suggerito: `Sales MS% (Bucket, LP)`
- Descrizione: Share or mix measure for the primary metric family.
- Suggerimenti: `Sales MS% (Bucket, LP)`, `MS%`, `Share`

### Primary Group QoQ Measure
- Binding key: `MOD_BIND_GROUP_1_QOQ_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.matrix.primary.qoq`
- Default suggerito: `Sales QoQ% (Bucket, LP)`
- Descrizione: Quarter-over-quarter delta percent for the primary metric family.
- Suggerimenti: `Sales QoQ% (Bucket, LP)`, `QoQ%`, `PPG% vs QoQ`

### Primary Group YoY Measure
- Binding key: `MOD_BIND_GROUP_1_YOY_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.matrix.primary.yoy`
- Default suggerito: `Sales YoY% (Bucket, LP)`
- Descrizione: Year-over-year delta percent for the primary metric family.
- Suggerimenti: `Sales YoY% (Bucket, LP)`, `YoY%`, `PPG% vs PY`

### Secondary Group ACT Measure
- Binding key: `MOD_BIND_GROUP_2_ACT_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.matrix.secondary.act`
- Default suggerito: `Promo Measure (Bucket, LP)`
- Descrizione: Current-value measure for the secondary metric family.
- Suggerimenti: `Promo Measure (Bucket, LP)`, `ACT`, `Current Value`

### Secondary Group Share Measure
- Binding key: `MOD_BIND_GROUP_2_SHARE_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.matrix.secondary.share`
- Default suggerito: `Promo MS% (Bucket, LP)`
- Descrizione: Share or mix measure for the secondary metric family.
- Suggerimenti: `Promo MS% (Bucket, LP)`, `MS%`, `Share`

### Secondary Group QoQ Measure
- Binding key: `MOD_BIND_GROUP_2_QOQ_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.matrix.secondary.qoq`
- Default suggerito: `Promo QoQ% (Bucket, LP)`
- Descrizione: Quarter-over-quarter delta percent for the secondary metric family.
- Suggerimenti: `Promo QoQ% (Bucket, LP)`, `QoQ%`, `PPG% vs QoQ`

### Secondary Group YoY Measure
- Binding key: `MOD_BIND_GROUP_2_YOY_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.matrix.secondary.yoy`
- Default suggerito: `Promo YoY% (Bucket, LP)`
- Descrizione: Year-over-year delta percent for the secondary metric family.
- Suggerimenti: `Promo YoY% (Bucket, LP)`, `YoY%`, `PPG% vs PY`

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
  -ModuleId bucket_metric_matrix_engine_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId bucket_metric_matrix_engine_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId bucket_metric_matrix_engine_mvp `
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