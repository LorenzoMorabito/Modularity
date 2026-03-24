# Desktop Pack Setup Handbook

Handbook operativo per preparare un workbench Power BI Desktop e promuovere un nuovo package semantic installabile.

## Obiettivo

Questo documento spiega il flusso `Desktop-first` del framework:

- come preparare il progetto di authoring
- come evitare i problemi tipici del setup iniziale
- come creare il baseline prima delle modifiche
- come modellare gli oggetti del modulo dentro Power BI Desktop
- come promuovere il delta come package semantic installabile
- come verificare e provare il package generato

## Perimetro del workflow

Questo handbook copre il workflow `promotion V1`:

- `semantic-only`
- nuovi oggetti module-owned
- authoring in Power BI Desktop su `PBIP`
- promotion verso package con `manifest.json` + `semantic/*.tmdl`

Non copre:

- export di report/page/visual
- modifiche a relazioni del target
- modifiche a tabelle target preesistenti
- promotion generalizzata di field parameters raw creati in Desktop

## Logica del workflow

Il flusso corretto e questo:

1. crei un clone pulito del progetto base
2. disattivi `Auto date/time`
3. verifichi che il semantic model sia pulito
4. congeli una baseline
5. apri Power BI Desktop e crei solo i nuovi asset del modulo
6. salvi e chiudi
7. lanci la promotion
8. leggi il report di promotion
9. opzionale: installi e testi il package su un consumer pulito

Il punto chiave e questo:

- il promotore non “capisce le tue intenzioni”
- confronta il `prima` e il `dopo`
- quindi tutto cio che cambia fuori dal perimetro ammesso puo bloccare la promotion

## Prerequisiti

Ti servono:

- repo `pbi-modularity` disponibile localmente
- un progetto `PBIP` base da usare come workbench
- Power BI Desktop
- accesso al comando `Invoke-PbiModularity.ps1`

Path tipici nel workspace corrente:

- workspace root:
  `C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity`
- cartella test/workbench:
  `C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\test`

## Regole di authoring

Durante il V1 devi rispettare queste regole:

- crea solo nuove tabelle del modulo
- usa naming `MOD ...` per la facade visibile
- usa naming `_MOD ...` per le tabelle tecniche
- non modificare tabelle target esistenti
- non modificare relazioni
- non modificare metadata globali del modello

Per i moduli `strict`:

- i riferimenti esterni a misure o colonne devono stare nel layer `_MOD ... Inputs`
- la tabella `MOD ...` deve lavorare solo sugli asset del modulo

## Setup iniziale del workbench

### 1. Crea un clone pulito

Esempio:

```powershell
Copy-Item `
  -Path "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\test\template_base_no_modify" `
  -Destination "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\test\test_012" `
  -Recurse
```

### 2. Apri il PBIP in Power BI Desktop

Esempio:

`C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\test\test_012\sales_template.pbip`

### 3. Disattiva `Auto date/time`

In Power BI Desktop:

- `File > Options and settings > Options`
- `Current File > Time intelligence`
- disattiva `Auto date/time`
- `Global > Time intelligence`
- disattiva `Auto date/time`

Poi salva e chiudi.

Nota:

- la pipeline ora sa neutralizzare gli artefatti standard `Auto date/time`
- ma la best practice resta comunque disattivarlo prima di iniziare

### 4. Verifica che il semantic model sia pulito

Controlla che non esistano artefatti `LocalDateTable_*` o `DateTableTemplate_*`:

```powershell
Get-ChildItem `
  -Path "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\test\test_012\sales_template.SemanticModel\definition" `
  -Recurse -File |
Select-String -Pattern "LocalDateTable_|DateTableTemplate_"
```

Output atteso:

- nessun risultato

## Baseline iniziale

Prima di toccare il modello, congela il baseline:

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command new-promotion-baseline `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\test\test_012\sales_template.pbip" `
  -ModuleId "switch_measure_desktop_mvp"
```

Output atteso:

- baseline path
- workbench mode
- numero tabelle baseline

## Authoring in Power BI Desktop

Dopo la baseline:

1. riapri il `PBIP`
2. crea solo gli oggetti del modulo
3. salva
4. chiudi Desktop

Per un modulo semantic `strict`, il pattern consigliato e questo:

- `_MOD <Name> Inputs`
  contiene i riferimenti esterni del consumer
- `MOD <Name>`
  contiene la parte visibile e riusabile del modulo

## Promotion del package

Dopo il save/close del workbench, lancia la promotion:

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command promote-semantic-module `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\test\test_012\sales_template.pbip" `
  -Domain "shared" `
  -ModuleId "switch_measure_desktop_mvp" `
  -OutputRoot "$env:TEMP\switch-measure-desktop-mvp" `
  -Force
```

Se vuoi scrivere il package direttamente nel dominio governato, puoi omettere `-OutputRoot`.

In quel caso il package viene creato sotto:

- `pbi-shared-domain/packages/<moduleId>`

e il catalogo del dominio viene aggiornato automaticamente.

## Cosa genera la promotion

Il risultato minimo e:

```text
<package-root>/
  manifest.json
  README.md
  PACKAGE.md
  semantic/
    <table1>.tmdl
    <table2>.tmdl
```

In piu la sessione di promotion salva:

- `promotion-report.json`
- `promotion-report.md`

nel consumer, sotto:

- `module-config/<projectId>/promotion-sessions/<moduleId>/`

## Come leggere il risultato

Se la promotion va bene, vedrai:

- package root
- semantic tables esportate
- numero external bindings rilevati
- path del report `json`
- path del report `md`

Se la promotion fallisce, i messaggi piu tipici sono:

- hai modificato una tabella target-owned
- hai toccato `relationships.tmdl`
- hai un riferimento esterno fuori dal layer `Inputs`
- una tabella nuova non rispetta il naming `MOD/_MOD`

## Esempio pratico completo

Esempio: modulo `switch_measure_desktop_mvp`.

### 1. Clone pulito

```powershell
Copy-Item `
  -Path "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\test\template_base_no_modify" `
  -Destination "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\test\test_012" `
  -Recurse
```

### 2. Disattiva `Auto date/time`, salva e chiudi

### 3. Check pulizia

```powershell
Get-ChildItem `
  -Path "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\test\test_012\sales_template.SemanticModel\definition" `
  -Recurse -File |
Select-String -Pattern "LocalDateTable_|DateTableTemplate_"
```

### 4. Baseline

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command new-promotion-baseline `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\test\test_012\sales_template.pbip" `
  -ModuleId "switch_measure_desktop_mvp"
```

### 5. Authoring in Desktop

Apri `sales_template.pbip` e crea:

Tabella tecnica:

```DAX
_MOD Switch Measure Inputs =
ROW ( "Column", BLANK() )
```

Misure nella tabella `_MOD Switch Measure Inputs`:

```DAX
Switch Measure Input Sales =
[Sales LE]
```

```DAX
Switch Measure Input Units =
[Counting Units]
```

Tabella visibile:

```DAX
MOD Switch Measure =
DATATABLE (
    "MetricKey", STRING,
    "MetricLabel", STRING,
    "SortOrder", INTEGER,
    {
        { "sales", "Sales", 1 },
        { "units", "Units", 2 }
    }
)
```

Misura finale:

```DAX
Switch Measure Value =
SWITCH (
    SELECTEDVALUE ( 'MOD Switch Measure'[MetricKey], "sales" ),
    "sales", '_MOD Switch Measure Inputs'[Switch Measure Input Sales],
    "units", '_MOD Switch Measure Inputs'[Switch Measure Input Units],
    BLANK()
)
```

Poi:

- nascondi `_MOD Switch Measure Inputs[Column]`
- nascondi `MOD Switch Measure[MetricKey]`
- nascondi `MOD Switch Measure[SortOrder]`
- ordina `MOD Switch Measure[MetricLabel]` per `SortOrder`
- salva e chiudi Desktop

### 6. Promotion

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command promote-semantic-module `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity" `
  -ProjectPath "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-sviluppi\powerbi-projects\test\test_012\sales_template.pbip" `
  -Domain "shared" `
  -ModuleId "switch_measure_desktop_mvp" `
  -OutputRoot "$env:TEMP\switch-measure-desktop-mvp" `
  -Force
```

Output atteso:

- `Semantic tables: _MOD Switch Measure Inputs, MOD Switch Measure`
- `External bindings: 2`

### 7. Installazione di prova del package generato

Su un consumer pulito puoi poi fare:

```powershell
pwsh -NoProfile -File "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity\pbi-modular-platform\Invoke-PbiModularity.ps1" `
  -Command install-wizard `
  -WorkspaceRoot "C:\work\MEN_Marketing\PBI_PROJECTS\pbi-modularity"
```

oppure il flusso manuale:

- `suggest-bindings`
- `validate`
- `install`
- `test`

## Best practice operative

- crea sempre il baseline prima di aprire il ciclo di authoring
- lavora su un clone pulito, non sul consumer produttivo
- disattiva sempre `Auto date/time`
- se possibile, chiudi Desktop prima della promotion
- usa nomi modulo stabili gia dall’inizio
- leggi sempre `promotion-report.md` prima di installare il package

## Output e log utili

Nel workbench troverai:

- `module-config/<projectId>/promotion-sessions/<moduleId>/baseline.json`
- `module-config/<projectId>/promotion-sessions/<moduleId>/promotion-report.json`
- `module-config/<projectId>/promotion-sessions/<moduleId>/promotion-report.md`

Nel package troverai:

- `manifest.json`
- `README.md`
- `PACKAGE.md`
- `semantic/*.tmdl`

## Limiti noti del V1

- solo package `semantic-only`
- niente export di visual/report
- niente promotion di modifiche a relazioni o tabelle target
- field parameters raw creati in Desktop non sono ancora un caso promotion supportato in modo generale

Quindi il V1 non e un “estrattore universale” di qualunque modifica fatta in Desktop. E un promotore governato per nuovi asset semantic module-owned.
