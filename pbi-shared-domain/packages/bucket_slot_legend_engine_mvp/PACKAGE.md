# Bucket Slot Legend Engine MVP

## Identita
- Modulo: `bucket_slot_legend_engine_mvp`
- Dominio: `shared`
- Versione: `0.1.0`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `experimental`
- Compatibilita consumer dichiarata: `shared/any-semantic-model-with-rankable-entity-dimension`
- Descrizione: Generic bucket slot and legend engine extracted from the legacy corporation bucket comparison logic.

## Caratteristiche
- Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.
- Usa binding guidato a ruoli espliciti, cosi ogni parametro ha un significato tecnico chiaro (`guided`).
- Espone una facade table business-facing: `MOD Bucket Slots`.

## Cosa installa
- Tabella semantic: `_MOD Bucket Slots Inputs`
- Tabella semantic: `_MOD Bucket Slots Targets`
- Tabella semantic: `_MOD Bucket Slots N`
- Tabella semantic: `_MOD Bucket Slots Slots`
- Tabella semantic: `_MOD Bucket Slots Legend`
- Tabella semantic: `MOD Bucket Slots`
- Tabelle tecniche nascoste dichiarate: `_MOD Bucket Slots Inputs`, `_MOD Bucket Slots Targets`, `_MOD Bucket Slots N`, `_MOD Bucket Slots Slots`, `_MOD Bucket Slots Legend`
- Tabella facade visibile: `MOD Bucket Slots`
- Non installa una report page pronta: il package fornisce solo asset semantic.

## Prerequisiti dichiarati
- Moduli dipendenti: nessuno
- Capability richieste: nessuna
- Core measures richieste: `MOD_BIND_VALUE_MEASURE`, `MOD_BIND_RANKING_MEASURE`
- Core columns richieste: `MOD_BIND_ENTITY_DIMENSION[Value]`

## Parametri di binding

### Entity Dimension
- Binding key: `MOD_BIND_ENTITY_DIMENSION[Value]`
- Tipo: `column`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.entity`
- Default suggerito: `T_DIM_CORPORATION[Corporation]`
- Descrizione: Dimension column used for target selection, TopN ranking, and legend aggregation.
- Suggerimenti: `Corporation`, `Company`, `Brand`, `Product`

### Value Measure
- Binding key: `MOD_BIND_VALUE_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.value`
- Default suggerito: `Sales Values`
- Descrizione: Measure aggregated for the selected target, TopN competitors, and Others bucket.
- Suggerimenti: `Sales Values`, `Values`, `Revenue`, `Actual`

### Ranking Measure
- Binding key: `MOD_BIND_RANKING_MEASURE`
- Tipo: `measure`
- Obbligatorio: `si`
- Ruolo semantico: `bucket.ranking`
- Default suggerito: `Sales Values`
- Descrizione: Measure used to rank the entity dimension and determine the TopN set.
- Suggerimenti: `Sales Values`, `Values`, `Share`, `Ranking`

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
  -ModuleId bucket_slot_legend_engine_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId bucket_slot_legend_engine_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId bucket_slot_legend_engine_mvp `
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