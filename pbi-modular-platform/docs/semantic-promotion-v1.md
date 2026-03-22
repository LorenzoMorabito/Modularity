# Semantic Promotion V1

Workflow V1 per promuovere nuovi asset semantic module-owned creati in Power BI Desktop verso package installabili del framework.

## Decisioni congelate

1. Modalita ufficiale workbench V1: `byPath-local-workbench`
2. Strategia binding V1: `strict`
3. Naming obbligatorio: una sola facade `MOD ...`, tutte le altre tabelle tecniche `_MOD ...`
4. Manifest generato: schema governato esistente con `type=semantic`, `classification=semantic-light`, `semanticImpact=additive`, `provides.semanticTables`, `semanticUx` e `bindingContract`
5. Pattern DAX supportati V1: pass-through semplici di misura esterna e selector semplici di colonna esterna nel layer `_MOD ... Inputs`

## Razionale

Il V1 non usa `Make changes to this model` come modalita ufficiale. Il workbench supportato e un progetto `PBIP` locale con semantic model referenziato `byPath`, perche:

- evita qualsiasi rischio di toccare il semantic target originale
- rende baseline e delta deterministici
- e compatibile con il folder `definition/` TMDL gia gestito dal framework

## Comandi

Creazione baseline:

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command new-promotion-baseline `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -ModuleId <MODULE_ID>
```

Promotion:

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command promote-semantic-module `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain <DOMAIN> `
  -ModuleId <MODULE_ID> `
  -OutputRoot <OUTPUT_ROOT>
```

Harness di test:

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command test-promotion `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH>
```

## Perimetro V1

Supportato:

- package `semantic-only`
- nuovi file `definition/tables/*.tmdl`
- riferimenti esterni semplici a misure
- riferimenti esterni semplici a colonne tramite selector nel layer inputs
- generazione automatica di `manifest.json`, `README.md`, `PACKAGE.md` e `semantic/*.tmdl`
- registrazione automatica nel `catalog/modules.json` del dominio quando l'output viene scritto dentro una repo-domain del workspace

Bloccato automaticamente:

- modifica di tabelle target-owned
- modifica di `relationships.tmdl`
- modifica di `model.tmdl`, `database.tmdl`, `expressions.tmdl`
- modifica di `cultures/*`
- riferimenti esterni fuori dal layer `_MOD ... Inputs`

## File di sessione

La baseline e il report di promotion vengono salvati sotto:

`module-config/<pbip>/promotion-sessions/<moduleId>/`

File prodotti:

- `baseline.json`
- `promotion-report.json`
- `promotion-report.md`

## Test automation V1

Il promotore dispone di un harness scenario-based in:

`pbi-modular-platform/promotion/testing/Invoke-PbiSemanticPromotionTests.ps1`

Fixture versionate:

- `promotion/testing/fixtures/golden/simple`
- `promotion/testing/fixtures/golden/multi`
- `promotion/testing/fixtures/failure/strict-outside-inputs`
- `promotion/testing/fixtures/targets`

Copertura attuale del harness:

- parse TMDL di fixture semplici
- classificazione external references
- generazione binding candidates
- generazione manifest
- delta classification su workbench reale
- golden path semplice
- golden path multi-table
- failure path target-owned table changed
- failure path relationships changed
- failure path strict reference outside `_MOD ... Inputs`
- idempotenza output package
- round-trip promotion -> catalog registration -> validate -> install -> test

## Limiti noti V1

- nessun export PBIR/report
- nessuna promotion di relazioni o metadata globali del modello
- nessuna placeholderization generalizzata di DAX complesso
- nessun supporto a authoring assisted fuori dai pattern strict supportati
- se `-OutputRoot` punta fuori dal dominio del workspace, il package viene generato ma non viene registrato nel catalogo del framework
