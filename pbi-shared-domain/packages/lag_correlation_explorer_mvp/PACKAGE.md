# Lag Correlation Explorer MVP

## Identita
- Modulo: `lag_correlation_explorer_mvp`
- Dominio: `shared`
- Versione: `0.1.0`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `experimental`
- Compatibilita consumer dichiarata: `shared/any-semantic-model-with-date-axis`
- Descrizione: Generic lag and correlation exploration package extracted from the legacy Product Analysis lag-selection logic.

## Caratteristiche
- Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.
- Usa binding guidato a ruoli espliciti, cosi ogni parametro ha un significato tecnico chiaro (`guided`).
- Espone una facade table business-facing: `MOD Lag Explorer`.

## Cosa installa
- Tabella semantic: `_MOD Lag Explorer Inputs`
- Tabella semantic: `_MOD Lag Explorer Lambda`
- Tabella semantic: `_MOD Lag Explorer MaxLag`
- Tabella semantic: `MOD Lag Explorer`
- Tabelle tecniche nascoste dichiarate: `_MOD Lag Explorer Inputs`, `_MOD Lag Explorer Lambda`, `_MOD Lag Explorer MaxLag`
- Tabella facade visibile: `MOD Lag Explorer`
- Non installa una report page pronta: il package fornisce solo asset semantic.

## Prerequisiti dichiarati
- Moduli dipendenti: nessuno
- Capability richieste: nessuna
- Core measures richieste: `MOD_BIND_DRIVER_MEASURE`, `MOD_BIND_RESPONSE_MEASURE`
- Core columns richieste: `MOD_BIND_PERIOD_AXIS[Value]`

## Parametri di binding

### Driver Measure
- Binding key: `MOD_BIND_DRIVER_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `lag.driver`
- Default suggerito: `Promo Spend`
- Descrizione: Metric treated as the lagged driver series.
- Suggerimenti: `Promo Spend`, `Spend`, `Investment`, `Driver`

### Response Measure
- Binding key: `MOD_BIND_RESPONSE_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `lag.response`
- Default suggerito: `Sales Values`
- Descrizione: Metric treated as the response series.
- Suggerimenti: `Sales Values`, `Values`, `Response`, `Outcome`

### Period Axis
- Binding key: `MOD_BIND_PERIOD_AXIS[Value]`
- Tipo: `column`
- Obbligatorio: `si`
- Ruolo semantico: `calendar.period`
- Default suggerito: `T_DIM_QUARTER[QuarterStartDay]`
- Descrizione: Ordered date column used for lag shifting and correlation windows.
- Suggerimenti: `QuarterStartDay`, `MonthStartDay`, `Date`, `Period`

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
  -ModuleId lag_correlation_explorer_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId lag_correlation_explorer_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId lag_correlation_explorer_mvp `
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