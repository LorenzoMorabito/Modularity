# Spend Bucket Pareto MVP

## Identita
- Modulo: `spend_bucket_pareto_mvp`
- Dominio: `shared`
- Versione: `0.1.0`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `experimental`
- Compatibilita consumer dichiarata: `shared/any-semantic-model-with-rankable-entity-and-spend-measure`
- Descrizione: Generic Pareto-style spend bucketing package extracted from the legacy GroupBySpending logic.

## Caratteristiche
- Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.
- Usa binding guidato a ruoli espliciti, cosi ogni parametro ha un significato tecnico chiaro (`guided`).
- Espone una facade table business-facing: `MOD Spend Buckets`.

## Cosa installa
- Tabella semantic: `_MOD Spend Buckets`
- Tabella semantic: `MOD Spend Buckets`
- Tabelle tecniche nascoste dichiarate: `_MOD Spend Buckets`
- Tabella facade visibile: `MOD Spend Buckets`
- Non installa una report page pronta: il package fornisce solo asset semantic.

## Prerequisiti dichiarati
- Moduli dipendenti: nessuno
- Capability richieste: nessuna
- Core measures richieste: `MOD_BIND_SPEND_MEASURE`
- Core columns richieste: `MOD_BIND_ENTITY_DIMENSION[Value]`

## Parametri di binding

### Entity Dimension
- Binding key: `MOD_BIND_ENTITY_DIMENSION[Value]`
- Tipo: `column`
- Obbligatorio: `si`
- Ruolo semantico: `spend.entity`
- Default suggerito: `T_DIM_PRODUCT[Product]`
- Descrizione: Dimension ranked by spend and bucketed into Pareto segments.
- Suggerimenti: `Product`, `Corporation`, `Brand`, `Country`

### Spend Measure
- Binding key: `MOD_BIND_SPEND_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `spend.value`
- Default suggerito: `Promo Spend`
- Descrizione: Measure used to rank the entity dimension and compute Pareto buckets.
- Suggerimenti: `Promo Spend`, `Spending`, `Investment`, `Values`

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
  -ModuleId spend_bucket_pareto_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId spend_bucket_pareto_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId spend_bucket_pareto_mvp `
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