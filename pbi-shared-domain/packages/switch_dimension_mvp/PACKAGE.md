# Switch Dimension MVP

<!-- PBI_PACKAGE_SHEET_STANDARD_V1 -->

## Identita
- Modulo: `switch_dimension_mvp`
- Dominio: `shared`
- Versione: `0.1.0`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `prototype`
- Compatibilita consumer dichiarata: `shared/any-semantic-model-with-at-least-four-categorical-columns`
- Descrizione: `Field parameter semantic-only che consente di cambiare la dimensione categoriale usata dai visual.`

## Caratteristiche
- Installa solo asset semantic.
- Espone una sola tabella facade visibile, senza pagina report pronta.
- Usa field parameter tokenizzati, compilati dal framework al momento dell'installazione.

## Cosa installa
- Tabella semantic: `MOD Switch Dimension`
- Punto di ingresso principale: colonna visibile `Switch Dimension` della tabella `MOD Switch Dimension`

## Prerequisiti dichiarati
- Moduli dipendenti: `nessuno`
- Capability richieste: `nessuna`
- Core measures richieste: `nessuna dichiarata`
- Core columns richieste: `MOD_BIND_DIMENSION_1[Value]`, `MOD_BIND_DIMENSION_2[Value]`, `MOD_BIND_DIMENSION_3[Value]`, `MOD_BIND_DIMENSION_4[Value]`

## Parametri di binding

- `MOD_BIND_DIMENSION_1[Value]`
  Colonna categoriale primaria da proporre nel field parameter.
- `MOD_BIND_DIMENSION_2[Value]`
  Seconda colonna categoriale disponibile nel selettore.
- `MOD_BIND_DIMENSION_3[Value]`
  Terza colonna categoriale disponibile nel selettore.
- `MOD_BIND_DIMENSION_4[Value]`
  Quarta colonna categoriale disponibile nel selettore.

## Cosa non fa
- Non installa visual o slicer pronti.
- Non gestisce un numero dinamico di dimensioni oltre le quattro previste.
- Non sostituisce il bisogno di un report configurato per usare il field parameter.

## Installazione corretta
- Parametri CLI base: `-ProjectPath`, `-Domain`, `-ModuleId`
- Parametri CLI consigliati per il binding: `-InteractiveUi`, `-SaveBindingProfileAs`, `-BindingProfileId`, `-MappingFile`

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command suggest-bindings `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId switch_dimension_mvp `
  -InteractiveUi `
  -SaveBindingProfileAs <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command validate `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId switch_dimension_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command install `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH> `
  -Domain shared `
  -ModuleId switch_dimension_mvp `
  -BindingProfileId <PROFILE_ID>
```

```powershell
pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `
  -Command test `
  -WorkspaceRoot <WORKSPACE_ROOT> `
  -ProjectPath <PROJECT_PATH>
```

## Uso consigliato
- Usa `Switch Dimension` in uno slicer e la colonna field parameter nei visual compatibili.
- Verifica dopo l'installazione che le quattro colonne bindate siano coerenti come livello di granularita e leggibilita.
- Evita di usare colonne tecniche o ID numerici come binding del selettore.

## File del package
- `manifest.json`: contratto del modulo, binding, output dichiarati e metadati installativi.
- `README.md`: descrizione business e guida rapida del modulo.
- `PACKAGE.md`: scheda installativa operativa del package.
- `semantic/`: asset semantic sorgente che il framework materializza nel consumer.
