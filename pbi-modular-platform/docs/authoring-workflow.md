# Authoring Workflow

Workflow per sviluppare package `semantic` tramite un sandbox di authoring isolato dal package runtime.

## Obiettivo

Consentire a chi sviluppa moduli di:

- partire da un package gia standardizzato
- generare un sandbox di authoring editabile in Tabular Editor
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
  -ModuleId <MODULE_ID> `
  [-AuthoringFormat te-folder|tmdl]
```

Default:

- `-AuthoringFormat te-folder`

Path di default:

- `te-folder`: `<package>/.authoring/<moduleId>`
- `tmdl`: `<package>/.authoring/<moduleId>.SemanticModel`

Il sandbox contiene:

- copie delle tabelle semantic dichiarate dal package
- tabelle stub per i binding `measure`
- tabelle stub per i binding `column`
- metadata `.pbi-modularity-authoring.json` per tracciare il round-trip

Il formato `te-folder` genera una struttura compatibile con Tabular Editor:

- `database.json`
- `tables/<Table>/...`
- `cultures/...`

Il formato `tmdl` resta disponibile come fallback tecnico.

### 2. Sync dal sandbox al package

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command sync-pack-from-authoring `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -Domain <DOMAIN> `
  -ModuleId <MODULE_ID> `
  [-AuthoringFormat te-folder|tmdl]
```

Il sync:

- legge solo le tabelle semantic gia dichiarate dal package
- ignora le tabelle stub di authoring
- auto-rileva il formato dal metadata quando non viene specificato
- aggiorna i file `semantic/*.tmdl` del package quando cambiano

## Workflow consigliato

1. crea il package con `new-module`
2. genera il sandbox con `new-authoring-model`
3. apri il sandbox `te-folder` in Tabular Editor
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
- il primo round-trip `te-folder -> tmdl` puo canonizzare il layout del file TMDL, anche senza cambi funzionali

## Motivazione architetturale

Il repo `modularity` resta TMDL-native a runtime.

Per l'authoring umano, il formato consigliato e `te-folder`, perche:

- si apre bene in Tabular Editor
- separa gli oggetti in file piccoli e leggibili
- rende piu facile il sync selettivo degli oggetti del modulo

Il formato `tmdl` resta supportato come fallback tecnico.
