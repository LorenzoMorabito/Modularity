# Authoring Workflow

Workflow MVP per sviluppare package `semantic` tramite un sandbox `.SemanticModel` isolato dal package runtime.

## Obiettivo

Consentire a chi sviluppa moduli di:

- partire da un package gia standardizzato
- generare un sandbox di authoring editabile in Tabular Editor o altri editor TMDL
- riportare nel package le modifiche semantic senza lavorare direttamente sui file runtime installabili

Il package resta il source of truth runtime.
Il sandbox e un ambiente di authoring temporaneo.

## Comandi

### 1. Generazione sandbox autore

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command new-authoring-model `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -Domain <DOMAIN> `
  -ModuleId <MODULE_ID>
```

Default output:

- `<package>/.authoring/<moduleId>.SemanticModel`

Il sandbox contiene:

- copie delle tabelle semantic dichiarate dal package
- tabelle stub per i binding `measure`
- tabelle stub per i binding `column`
- metadata `.pbi-modularity-authoring.json` per tracciare il round-trip

### 2. Sync dal sandbox al package

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command sync-pack-from-authoring `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -Domain <DOMAIN> `
  -ModuleId <MODULE_ID>
```

Il sync:

- legge solo le tabelle semantic gia dichiarate dal package
- ignora le tabelle stub di authoring
- aggiorna i file `semantic/*.tmdl` del package quando cambiano

## Workflow consigliato

1. crea il package con `new-module`
2. genera il sandbox con `new-authoring-model`
3. apri il sandbox `.SemanticModel` in Tabular Editor / editor TMDL
4. modifica solo le tabelle del modulo
5. salva
6. esegui `sync-pack-from-authoring`
7. esegui `test-module`
8. esegui install e test su un consumer

## Vincoli MVP

- supporta solo package `semantic`
- il sync e `strict`: aggiorna solo le tabelle gia dichiarate in `manifest.json`
- non fa ancora discovery libera di nuove tabelle create nel sandbox
- non gestisce ancora il round-trip degli asset `report/`

## Motivazione architetturale

Il repo `modularity` e TMDL-native. Per questo il formato canonico del sandbox autore e `.SemanticModel`, non `.bim`.

Il `.bim` puo restare un artifact intermedio o un formato di esportazione, ma non e il source of truth raccomandato del workflow.
