# TopN Target Driver Bundle MVP

## Identita
- Modulo: `topn_target_driver_bundle_mvp`
- Dominio: `shared`
- Versione: `0.2.0`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `experimental`
- Rendering strategy: `topn-target-driver`
- Compatibilita consumer dichiarata: `shared/any-semantic-model-with-rankable-dimensions`
- Descrizione: Generic TopN plus optional target-driven ranking bundle extracted from the legacy TopN, target entity, and top-by selector logic, now with a reusable report page.

## Caratteristiche
- Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.
- Usa binding collection-guided: l'installer guida la scelta di insiemi curati di dimensioni o misure.
- Permette di controllare il perimetro installato scegliendo quante colonne o misure esporre.
- Include una report page starter utile per verificare il modulo subito dopo l'installazione.
- Espone una facade table business-facing: `MOD TopN Driver`.

## Cosa installa
- Tabella semantic: `_MOD TopN Driver Inputs`
- Tabella semantic: `_MOD TopN Driver Grains`
- Tabella semantic: `_MOD TopN Driver Metrics`
- Tabella semantic: `_MOD TopN Driver Targets`
- Tabella semantic: `_MOD TopN Driver N`
- Tabella semantic: `MOD TopN Driver`
- Tabelle tecniche nascoste dichiarate: `_MOD TopN Driver Inputs`, `_MOD TopN Driver Grains`, `_MOD TopN Driver Metrics`, `_MOD TopN Driver Targets`, `_MOD TopN Driver N`
- Tabella facade visibile: `MOD TopN Driver`
- Report page: `TopN Target Driver` (`d2f8b9316ca44e2ca19f`)

## Prerequisiti dichiarati
- Moduli dipendenti: nessuno
- Capability richieste: nessuna
- Core measures richieste: nessuna dichiarata
- Core columns richieste: nessuna dichiarata

## Parametri di binding

### Entity Dimensions
- Collection id: `dimensions`
- Tipo: `column`
- Cardinalita: min `1`, max `4`, visibili di default `2`
- Pattern binding: `MOD_BIND_DIMENSION_<n>[Value]`
- Descrizione: Choose the entity columns that can be ranked and optionally selected as targets.
- Default `Dimension 1`: Primary ranking grain; valore suggerito `T_DIM_PRODUCT[Product]`; suggerimenti `Product`, `Brand`, `SKU`
- Default `Dimension 2`: Secondary ranking grain; valore suggerito `T_DIM_CORPORATION[Corporation]`; suggerimenti `Corporation`, `Company`, `Manufacturer`
- Default `Dimension 3`: Additional ranking grain; valore suggerito `T_DIM_COUNTRY[Country]`; suggerimenti `Country`, `Market`, `Region`
- Default `Dimension 4`: Additional ranking grain; valore suggerito `T_DIM_MOLECULE[MoleculeNorm]`; suggerimenti `Molecule`, `Ingredient`, `Segment`

### Ranking Measures
- Collection id: `measures`
- Tipo: `measure`
- Cardinalita: min `1`, max `6`, visibili di default `2`
- Pattern binding: `MOD_BIND_MEASURE_<n>`
- Descrizione: Choose the measures available for TopN ranking and target comparison.
- Default `Measure 1`: Default ranking metric; valore suggerito `Sales Values`; suggerimenti `Sales Values`, `Values`, `Revenue`
- Default `Measure 2`: Alternative ranking metric; valore suggerito `Promo Spend`; suggerimenti `Promo Spend`, `Spend`, `Investment`
- Default `Measure 3`: Alternative ranking metric; valore suggerito `Sales Values Î” vs PY`; suggerimenti `Values PPG%`, `Sales Values Î” vs PY`, `Growth`
- Default `Measure 4`: Alternative ranking metric; valore suggerito `Sales Units`; suggerimenti `Sales Units`, `Units`, `Volume`
- Default `Measure 5`: Alternative ranking metric; valore suggerito `Fin ACT`; suggerimenti `Fin ACT`, `Actual`, `ACT`
- Default `Measure 6`: Alternative ranking metric; valore suggerito `Fin BDG`; suggerimenti `Fin BDG`, `Budget`, `BDG`

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
  -ModuleId topn_target_driver_bundle_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId topn_target_driver_bundle_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId topn_target_driver_bundle_mvp `
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