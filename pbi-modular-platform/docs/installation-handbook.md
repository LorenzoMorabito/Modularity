# Installation Handbook

Handbook operativo per installare package in `pbi-modularity`.

## Obiettivo

Questo documento spiega:

- la logica del flusso di installazione
- i comandi da usare
- il workflow consigliato via wizard
- il workflow equivalente via CLI
- un esempio pratico completo

## Concetti chiave

Prima di installare un package, conviene distinguere bene questi 4 elementi:

- `workspace root`
  La root della repo `pbi-modularity`, cioe il catalogo dei package disponibili.
- `consumer project`
  Il progetto `PBIP` in cui vuoi installare il modulo.
- `package`
  Il modulo installabile scelto dal catalogo, per esempio `switch_dimension_mvp`.
- `binding`
  La mappatura tra i placeholder del package e le misure/colonne reali del consumer.

In pratica il framework non copia semplicemente file nel progetto target. Prima verifica che il consumer abbia gli asset giusti, poi costruisce o legge il binding, valida il contratto e solo dopo installa.

## Logica del workflow

Il flusso logico corretto e sempre questo:

1. individui il `PBIP` target
2. scegli il package da installare
3. controlli i prerequisiti
4. costruisci il binding verso misure/colonne del consumer
5. esegui `validate`
6. esegui `install`
7. chiudi con `test`

Questo ordine e importante:

- `validate` e il dry-run logico del contratto
- `install` modifica il consumer e crea snapshot/log
- `test` controlla che il progetto finale resti sano

## Prerequisiti

Prima di partire, ti servono:

- repo `pbi-modularity` disponibile localmente
- consumer `PBIP` disponibile localmente
- package presente in un catalogo di dominio
- modello consumer gia compatibile con il package scelto

Path tipici nel workspace corrente:

- workspace root: `C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity`
- project path: `C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\<project>\<project>.pbip`

## Workflow consigliato

Il percorso consigliato per un utente e `install-wizard`.

Perche:

- evita di ricordare tutti i passaggi a mano
- guida selezione package, pre-check, binding e install
- riusa la binding UI gia presente nel framework

### Step 1: vedere i package disponibili

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command list `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity"
```

Se vuoi filtrare un dominio:

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command list `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -Domain "shared"
```

### Step 2: aprire il wizard

Puoi aprire il wizard in due modi:

- modalita guidata completa, passando solo `WorkspaceRoot`
- modalita precompilata, passando anche `ProjectPath`, `Domain` e `ModuleId`

Versione minima:

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command install-wizard `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity"
```

Versione precompilata:

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command install-wizard `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "<PROJECT_PATH>" `
  -Domain "<DOMAIN>" `
  -ModuleId "<MODULE_ID>" `
  -SaveBindingProfileAs "<PROFILE_ID>"
```

### Step 3: usare il wizard

La sequenza interna del wizard e:

1. `Check`
   Verifica package, target e prerequisiti minimi.
2. `Configure Bindings`
   Apre la binding UI.
3. `Save Profile`
   Salva il profilo di binding nel consumer.
4. `Test Bindings`
   Controlla se il package e installabile con quella mappatura.
5. `Apply`
   Conferma il binding.
6. `Install`
   Esegue l’installazione reale.

## Workflow manuale CLI

Se non vuoi usare il wizard completo, il flusso manuale e questo.

### 1. Suggerire o costruire i binding

Versione con UI di binding:

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command suggest-bindings `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "<PROJECT_PATH>" `
  -Domain "<DOMAIN>" `
  -ModuleId "<MODULE_ID>" `
  -InteractiveUi `
  -SaveBindingProfileAs "<PROFILE_ID>"
```

Output atteso:

- elenco binding key
- valore scelto o suggerito
- salvataggio del profilo

### 2. Validare

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command validate `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "<PROJECT_PATH>" `
  -Domain "<DOMAIN>" `
  -ModuleId "<MODULE_ID>" `
  -BindingProfileId "<PROFILE_ID>"
```

Se tutto e corretto, il campo chiave e:

- `IsValid = True`

### 3. Installare

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command install `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "<PROJECT_PATH>" `
  -Domain "<DOMAIN>" `
  -ModuleId "<MODULE_ID>" `
  -BindingProfileId "<PROFILE_ID>"
```

Output atteso:

- snapshot creato
- install completata
- stato governance
- path del log

### 4. Testare il consumer finale

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command test `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "<PROJECT_PATH>"
```

Output atteso:

- `Errors=0`
- `Warnings=0`

## Esempio pratico completo

Esempio con il package `switch_dimension_mvp`.

Scenario:

- dominio: `shared`
- package: `switch_dimension_mvp`
- consumer: un `PBIP` con almeno queste colonne disponibili:
  - `Country[Country]`
  - `Corporation[Corporation]`
  - `Product[Product]`
  - `Molecule[Molecule]`

### Versione consigliata: wizard

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command install-wizard `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "<PROJECT_PATH>" `
  -Domain "shared" `
  -ModuleId "switch_dimension_mvp" `
  -SaveBindingProfileAs "switch_dimension_mvp_v1"
```

Nel wizard, seleziona:

- `Dimension 1` -> `Country[Country]`
- `Dimension 2` -> `Corporation[Corporation]`
- `Dimension 3` -> `Product[Product]`
- `Dimension 4` -> `Molecule[Molecule]`

Poi:

1. `Save Profile`
2. `Test Bindings`
3. `Apply`
4. `Install`

### Versione equivalente via CLI

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command suggest-bindings `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "<PROJECT_PATH>" `
  -Domain "shared" `
  -ModuleId "switch_dimension_mvp" `
  -InteractiveUi `
  -SaveBindingProfileAs "switch_dimension_mvp_v1"
```

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command validate `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "<PROJECT_PATH>" `
  -Domain "shared" `
  -ModuleId "switch_dimension_mvp" `
  -BindingProfileId "switch_dimension_mvp_v1"
```

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command install `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "<PROJECT_PATH>" `
  -Domain "shared" `
  -ModuleId "switch_dimension_mvp" `
  -BindingProfileId "switch_dimension_mvp_v1"
```

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command test `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "<PROJECT_PATH>"
```

## Dove scrive il framework

Dopo il binding e l’installazione, il consumer mantiene gli artefatti operativi sotto `module-config/<projectId>/`.

Tipicamente troverai:

- `mapping-profiles/`
  profili di binding salvati
- `installed-modules.json`
  stato installato del progetto
- `logs/`
  log delle operazioni
- `snapshots/`
  snapshot utili per rollback e audit

## Come leggere i risultati

Quando il flusso va bene:

- `validate` restituisce `IsValid = True`
- `install` stampa `Installed module ...`
- `test` restituisce `No findings`

Quando il flusso non va bene:

- `MissingMeasures` o `MissingColumns`
  il consumer non ha gli asset richiesti
- binding errato
  hai scelto una misura/colonna semanticamente sbagliata
- governance fail
  il modulo o il progetto superano una regola di controllo

## Errori frequenti

### 1. Il package esiste ma non si installa

Di solito il problema e uno di questi:

- binding non completo
- modulo scelto non compatibile con il consumer
- hai usato il package giusto ma il modello non ha ancora le misure helper richieste

### 2. `validate` fallisce ma il package e corretto

Di solito significa che:

- il package e sano
- il consumer non offre ancora i campi richiesti

Quindi va corretto il consumer o va scelto un altro package.

### 3. L’installazione e andata, ma il risultato nel report non e corretto

In quel caso il problema di solito non e l’installer ma uno di questi:

- binding semanticamente sbagliato
- package installato correttamente ma non ancora usato nel report
- report ancora non riallineato ai nuovi asset installati

## Regola pratica

Per un utente operativo, la scorciatoia mentale giusta e questa:

- `list`
  vedo cosa esiste
- `install-wizard`
  faccio il flusso guidato
- `test`
  confermo che il consumer finale e sano

Per un utente tecnico:

- `suggest-bindings`
- `validate`
- `install`
- `test`

Questo e il workflow standard da seguire salvo casi speciali di debug o automazione.
