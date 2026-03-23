# Switch Measure MVP

<!-- PBI_PACKAGE_SHEET_STANDARD_V1 -->

## Identita
- Modulo: `switch_measure_mvp`
- Dominio: `shared`
- Versione: `0.1.0`
- Tipo: `semantic`
- Classification: `semantic-light`
- Semantic impact: `additive`
- Stato: `prototype`
- Compatibilita consumer dichiarata: `da validare nel collaudo V1`
- Descrizione: `Selettore semantico di misure promosso da workbench Desktop.`

## Caratteristiche
- Promotion V1 semantic-only.
- Fail-fast su tabelle target, relazioni e metadata globali fuori perimetro.
- Pattern binding supportati automaticamente: [Measure] semplice univoca e selector SELECTEDVALUE/VALUES/DISTINCT(Table[Column]) nel layer _MOD ... Inputs.

## Cosa installa
- `_MOD Switch Measure Inputs`
- `MOD Switch Measure`

## Prerequisiti dichiarati
- Moduli dipendenti: `nessuno`
- Capability richieste: `nessuna`
- Core measures richieste: `MOD_BIND_COUNTING_UNITS, MOD_BIND_SALES_LE`
- Core columns richieste: ``

## Parametri di binding
- `MOD_BIND_COUNTING_UNITS` -> `Counting Units`
- `MOD_BIND_SALES_LE` -> `Sales LE`

## Cosa non fa
- Non promuove report, visual, bookmark o asset PBIR.
- Non accetta modifiche target-owned o file globali TMDL fuori perimetro.

## Installazione corretta
- Parametri CLI base: `-ProjectPath`, `-Domain`, `-ModuleId`
- Parametri CLI consigliati per il binding: `-InteractiveUi`, `-SaveBindingProfileAs`, `-BindingProfileId`

## Uso consigliato
- Validare sempre il package con `test-module` e poi fare smoke-install su un consumer sandbox.

## File del package
- `manifest.json`: contratto del modulo promosso.
- `README.md`: descrizione business e guida rapida.
- `PACKAGE.md`: scheda installativa operativa del package.
- `semantic/`: tabelle `.tmdl` module-owned esportate dal workbench.
