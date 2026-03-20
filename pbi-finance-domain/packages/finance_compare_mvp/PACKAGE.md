# Finance Compare MVP

## Identita
- Modulo: `finance_compare_mvp`
- Dominio: `finance`
- Versione: `0.2.2`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `prototype`
- Compatibilita consumer dichiarata: `marketing/product-analysis-core`
- Descrizione: Reusable compare module with one primary metric, two selectable reference metrics, and a time axis.

## Caratteristiche
- Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.
- Usa binding guidato a ruoli espliciti, cosi ogni parametro ha un significato tecnico chiaro (`guided`).
- Include una report page starter utile per verificare il modulo subito dopo l'installazione.
- Espone una facade table business-facing: `MOD Finance Compare`.

## Cosa installa
- Tabella semantic: `_MOD Finance Compare Inputs`
- Tabella semantic: `_MOD Finance Compare Selector`
- Tabella semantic: `MOD Finance Compare`
- Tabelle tecniche nascoste dichiarate: `_MOD Finance Compare Inputs`, `_MOD Finance Compare Selector`
- Tabella facade visibile: `MOD Finance Compare`
- Report page: `Metric Compare` (`8a4f2d4d3f11450ab001`)

## Prerequisiti dichiarati
- Moduli dipendenti: nessuno
- Capability richieste: nessuna
- Core measures richieste: `MOD_BIND_PRIMARY_MEASURE`, `MOD_BIND_REFERENCE_MEASURE_1`, `MOD_BIND_REFERENCE_MEASURE_2`
- Core columns richieste: `MOD_BIND_PERIOD_AXIS[Value]`

## Parametri di binding

### Primary Measure
- Binding key: `MOD_BIND_PRIMARY_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `compare.primary`
- Default suggerito: `Fin ACT`
- Descrizione: Main metric displayed as the current value in the compare visual.
- Suggerimenti: `Fin ACT`, `ACT`, `Actual`, `Current`, `ACT Mth`

### Reference Measure 1
- Binding key: `MOD_BIND_REFERENCE_MEASURE_1`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `compare.reference.1`
- Default suggerito: `Fin BDG`
- Descrizione: First reference metric offered in the comparison selector.
- Suggerimenti: `Fin BDG`, `BDG`, `Budget`, `Target`, `Plan`, `BDG Mth`

### Reference Measure 2
- Binding key: `MOD_BIND_REFERENCE_MEASURE_2`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `compare.reference.2`
- Default suggerito: `Fin ACT PY`
- Descrizione: Second reference metric offered in the comparison selector.
- Suggerimenti: `Fin ACT PY`, `PY`, `Previous Year`, `Prior Year`, `PY Mth`

### Period Axis
- Binding key: `MOD_BIND_PERIOD_AXIS[Value]`
- Tipo: `column`
- Obbligatorio: `si`
- Ruolo semantico: `calendar.period`
- Default suggerito: `T_DIM_MONTH[MonthStartDay]`
- Descrizione: Time column used on the trend axis of the compare visuals.
- Suggerimenti: `MonthStartDay`, `Month Date`, `Month`, `Quarter Date`, `Date`

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
  -Domain finance `
  -ModuleId finance_compare_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain finance `
  -ModuleId finance_compare_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain finance `
  -ModuleId finance_compare_mvp `
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