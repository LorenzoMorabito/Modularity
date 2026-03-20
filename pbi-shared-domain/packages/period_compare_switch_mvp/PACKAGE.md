# Period Compare Switch MVP

## Identita
- Modulo: `period_compare_switch_mvp`
- Dominio: `shared`
- Versione: `0.1.0`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `experimental`
- Compatibilita consumer dichiarata: `shared/any-semantic-model`
- Descrizione: Generic short-vs-rolling period comparison selector extracted from the legacy Product Analysis period switch logic.

## Caratteristiche
- Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.
- Usa binding guidato a ruoli espliciti, cosi ogni parametro ha un significato tecnico chiaro (`guided`).
- Espone una facade table business-facing: `MOD Period Compare`.

## Cosa installa
- Tabella semantic: `MOD Period Compare`
- Tabella facade visibile: `MOD Period Compare`
- Non installa una report page pronta: il package fornisce solo asset semantic.

## Prerequisiti dichiarati
- Moduli dipendenti: nessuno
- Capability richieste: nessuna
- Core measures richieste: `MOD_BIND_SHORT_CURRENT_MEASURE`, `MOD_BIND_SHORT_REFERENCE_MEASURE`, `MOD_BIND_LONG_CURRENT_MEASURE`, `MOD_BIND_LONG_REFERENCE_MEASURE`
- Core columns richieste: nessuna dichiarata

## Parametri di binding

### Short Current Measure
- Binding key: `MOD_BIND_SHORT_CURRENT_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `period.short.current`
- Default suggerito: `Sales Values`
- Descrizione: Metric used when the selector is on the short-horizon mode.
- Suggerimenti: `Sales Values`, `Values`, `ACT`, `Current`

### Short Reference Measure
- Binding key: `MOD_BIND_SHORT_REFERENCE_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `period.short.reference`
- Default suggerito: `Sales Values PY`
- Descrizione: Reference metric used for the short-horizon mode.
- Suggerimenti: `Sales Values PY`, `PY`, `Previous Year`, `Reference`

### Rolling Current Measure
- Binding key: `MOD_BIND_LONG_CURRENT_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `period.long.current`
- Default suggerito: `Sales Values MAT`
- Descrizione: Metric used when the selector is on the rolling-horizon mode.
- Suggerimenti: `Sales Values MAT`, `MAT`, `Rolling`, `Current MAT`

### Rolling Reference Measure
- Binding key: `MOD_BIND_LONG_REFERENCE_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `period.long.reference`
- Default suggerito: `Sales Values MAT PY`
- Descrizione: Reference metric used for the rolling-horizon mode.
- Suggerimenti: `Sales Values MAT PY`, `MAT PY`, `Rolling PY`, `Previous Year MAT`

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
  -ModuleId period_compare_switch_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId period_compare_switch_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId period_compare_switch_mvp `
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