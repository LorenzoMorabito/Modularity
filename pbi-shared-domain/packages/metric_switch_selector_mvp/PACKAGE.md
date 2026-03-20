# Metric Switch Selector MVP

## Identita
- Modulo: `metric_switch_selector_mvp`
- Dominio: `shared`
- Versione: `0.1.0`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `experimental`
- Rendering strategy: `metric-switch`
- Compatibilita consumer dichiarata: `shared/any-semantic-model`
- Descrizione: Generic collection-based metric selector extracted from the legacy sales, promo, and competitive measure switch tables.

## Caratteristiche
- Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.
- Usa binding collection-guided: l'installer guida la scelta di insiemi curati di dimensioni o misure.
- Permette di controllare il perimetro installato scegliendo quante colonne o misure esporre.
- Espone una facade table business-facing: `MOD Metric Switch`.

## Cosa installa
- Tabella semantic: `_MOD Metric Switch Inputs`
- Tabella semantic: `MOD Metric Switch`
- Tabelle tecniche nascoste dichiarate: `_MOD Metric Switch Inputs`
- Tabella facade visibile: `MOD Metric Switch`
- Non installa una report page pronta: il package fornisce solo asset semantic.

## Prerequisiti dichiarati
- Moduli dipendenti: nessuno
- Capability richieste: nessuna
- Core measures richieste: nessuna dichiarata
- Core columns richieste: nessuna dichiarata

## Parametri di binding

### Measures
- Collection id: `measures`
- Tipo: `measure`
- Cardinalita: min `1`, max `8`, visibili di default `3`
- Pattern binding: `MOD_BIND_MEASURE_<n>`
- Descrizione: Choose the measures exposed by the selector.
- Default `Measure 1`: Primary selectable metric; valore suggerito `Sales Values`; suggerimenti `Sales Values`, `Values`, `Revenue`
- Default `Measure 2`: Secondary selectable metric; valore suggerito `Promo Spend`; suggerimenti `Promo Spend`, `Spend`, `Investment`
- Default `Measure 3`: Third selectable metric; valore suggerito `Sales Units`; suggerimenti `Sales Units`, `Units`, `Volume`
- Default `Measure 4`: Additional selectable metric; valore suggerito `Fin ACT`; suggerimenti `Fin ACT`, `Actual`, `ACT`
- Default `Measure 5`: Additional selectable metric; valore suggerito `Fin BDG`; suggerimenti `Fin BDG`, `Budget`, `BDG`
- Default `Measure 6`: Additional selectable metric; valore suggerito `Fin ACT PY`; suggerimenti `Fin ACT PY`, `Previous Year`, `PY`
- Default `Measure 7`: Additional selectable metric; valore suggerito `Promo Contacts`; suggerimenti `Promo Contacts`, `Contacts`, `Calls`
- Default `Measure 8`: Additional selectable metric; valore suggerito `Promo Details`; suggerimenti `Promo Details`, `Details`, `Detailing`

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
  -ModuleId metric_switch_selector_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId metric_switch_selector_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId metric_switch_selector_mvp `
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