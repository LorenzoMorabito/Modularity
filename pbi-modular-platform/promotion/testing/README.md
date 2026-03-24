# Semantic Promotion Testing

Harness di test scenario-based per `new-promotion-baseline` e `promote-semantic-module`.

## Entry point

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command test-promotion `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH>
```

Se `ProjectPath` non viene passato, il comando prova a risolvere il consumer di test standard sotto il workspace locale. In assenza di un PBIP sorgente valido, esegue solo i test unitari.

## Fixture

- `fixtures/targets`
  target semantic minimo per parser e classifier
- `fixtures/golden/simple`
  modulo semantic minimale con un input table e una facade table
- `fixtures/golden/multi`
  modulo semantic con una facade table e due hidden tables
- `fixtures/failure/strict-outside-inputs`
  caso negativo per strict mode
- `fixtures/failure/qualified-measure-in-inputs`
  caso negativo per riferimento qualificato a misura dentro `_MOD ... Inputs`

## Output

Per default il comando salva evidenze sotto:

`promotion/testing/evidence/<timestamp>/`

File principali:

- `summary.json`
- `summary.md`
- cartelle per singolo caso con log e artefatti

## Scenari coperti

- unit parse/classification/binding/manifest
- unit strict gate su misura ambigua
- unit binding coverage su ref non placeholderizzabile
- delta extraction
- golden path package semplice
- golden path multi-table
- failure path su tabelle target-owned
- failure path su `relationships.tmdl`
- failure path strict fuori da `_MOD ... Inputs`
- failure path su misura qualificata dentro `_MOD ... Inputs`
- normalizzazione di artefatti `Auto date/time`
- idempotenza
- round-trip installativo su sandbox workspace
