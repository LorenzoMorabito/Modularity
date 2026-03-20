# FlexTablePivot

## Identita
- Modulo: `flex_metrics_table_mvp`
- Dominio: `marketing`
- Versione: `0.4.2`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `prototype`
- Rendering strategy: `flex-pivot`
- Compatibilita consumer dichiarata: `marketing/product-analysis-core`, `marketing/product-analysis-flextable`
- Descrizione: Reusable pivot-style metrics table with collection-based dimension and metric binding.

## Caratteristiche
- Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.
- Usa binding collection-guided: l'installer guida la scelta di insiemi curati di dimensioni o misure.
- Permette di controllare il perimetro installato scegliendo quante colonne o misure esporre.
- Include una report page starter utile per verificare il modulo subito dopo l'installazione.
- Espone una facade table business-facing: `MOD Flex Pivot`.

## Cosa installa
- Tabella semantic: `_MOD Flex Pivot Inputs`
- Tabella semantic: `_MOD Flex Pivot Selector`
- Tabella semantic: `_MOD Flex Pivot Axis`
- Tabella semantic: `MOD Flex Pivot`
- Tabelle tecniche nascoste dichiarate: `_MOD Flex Pivot Inputs`, `_MOD Flex Pivot Selector`, `_MOD Flex Pivot Axis`
- Tabella facade visibile: `MOD Flex Pivot`
- Report page: `Flexible Metrics Pivot` (`6f8d2c1e4b5a70918342`)

## Prerequisiti dichiarati
- Moduli dipendenti: nessuno
- Capability richieste: nessuna
- Core measures richieste: nessuna dichiarata
- Core columns richieste: nessuna dichiarata

## Parametri di binding

### Dimensions
- Collection id: `dimensions`
- Tipo: `column`
- Cardinalita: min `1`, max `6`, visibili di default `1`
- Pattern binding: `MOD_BIND_DIMENSION_<n>[Value]`
- Descrizione: Choose the dimensions exposed by the pivot table.
- Default `Dimension 1`: Primary row dimension; valore suggerito `T_DIM_COUNTRY[Country]`; suggerimenti `Country`, `Market`, `Region`
- Default `Dimension 2`: Secondary row dimension; valore suggerito `T_DIM_PRODUCT[Product]`; suggerimenti `Product`, `Brand`, `SKU`
- Default `Dimension 3`: Additional row dimension; valore suggerito `T_DIM_CORPORATION[Corporation]`; suggerimenti `Corporation`, `Company`, `Business Unit`
- Default `Dimension 4`: Additional row dimension; valore suggerito `T_DIM_MOLECULE[MoleculeNorm]`; suggerimenti `Molecule`, `Ingredient`, `Diagnosis`
- Default `Dimension 5`: Additional row dimension; valore suggerito `T_DIM_QUARTER[QuarterKey]`; suggerimenti `Quarter`, `Month`, `Period`
- Default `Dimension 6`: Additional row dimension; valore suggerito `T_DIM_ACT4[ATC4]`; suggerimenti `ATC4`, `Class`, `Segment`

### Measures
- Collection id: `measures`
- Tipo: `measure`
- Cardinalita: min `1`, max `10`, visibili di default `1`
- Pattern binding: `MOD_BIND_MEASURE_<n>`
- Descrizione: Choose the metrics exposed by the pivot table.
- Default `Measure 1`: Primary metric; valore suggerito `Sales Values`; suggerimenti `Sales Values`, `Values`, `Revenue`, `Net Sales`
- Default `Measure 2`: Secondary metric; valore suggerito `Sales Units`; suggerimenti `Sales Units`, `Units`, `Volume`
- Default `Measure 3`: Additional metric; valore suggerito `Counting Units`; suggerimenti `Counting Units`, `Count`, `Transactions`
- Default `Measure 4`: Additional metric; valore suggerito `Promo Spend`; suggerimenti `Promo Spend`, `Spend`, `Investment`
- Default `Measure 5`: Additional metric; valore suggerito `Promo Details`; suggerimenti `Promo Details`, `Details`, `Detailing`
- Default `Measure 6`: Additional metric; valore suggerito `Promo Contacts`; suggerimenti `Promo Contacts`, `Contacts`, `Calls`
- Default `Measure 7`: Additional metric; valore suggerito `Promo Weighted Calls`; suggerimenti `Promo Weighted Calls`, `Weighted Calls`, `Weighted Contacts`
- Default `Measure 8`: Additional metric; valore suggerito `Fin ACT`; suggerimenti `Fin ACT`, `Actual`, `ACT`
- Default `Measure 9`: Additional metric; valore suggerito `Fin BDG`; suggerimenti `Fin BDG`, `Budget`, `BDG`, `Target`
- Default `Measure 10`: Additional metric; valore suggerito `Fin ACT PY`; suggerimenti `Fin ACT PY`, `Previous Year`, `PY`, `Prior Year`

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
  -Domain marketing `
  -ModuleId flex_metrics_table_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain marketing `
  -ModuleId flex_metrics_table_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain marketing `
  -ModuleId flex_metrics_table_mvp `
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
- Nelle collection-guided evita di esporre piu dimensioni o misure del necessario: troppi item peggiorano UX e manutenzione.
- Se il package installa una pagina report, usala per smoke test funzionale ma non trattarla come template definitivo di business.

## File del package
- `manifest.json`: contratto del modulo, binding, output dichiarati e metadati installativi.
- `README.md`: note descrittive, contesto di estrazione o informazioni storiche del package.
- `PACKAGE.md`: scheda installativa locale del package.
- `semantic/`: asset semantic sorgente che il framework materializza nel consumer.
- `report/`: eventuali page e visual asset installati nel report consumer.