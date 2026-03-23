# Switch Dimension MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI una tabella field parameter riusabile che permette di cambiare la dimensione categoriale usata nei visual.

Non crea un report pronto. Aggiunge invece un selettore semantico che puoi usare in slicer, axis, legend o colonne di visual compatibili con i field parameters.

## Cosa fa

Permette di passare da una dimensione all'altra, per esempio da Country a Corporation, Product o Molecule, senza duplicare ogni visual.

## Cosa fornisce

- una tabella semantic `MOD Switch Dimension`
- una colonna visibile da usare come selettore della dimensione
- il wiring field parameter necessario per usare il selettore nei visual compatibili

## Quando utilizzarlo

Usalo quando vuoi lasciare all'utente la scelta della dimensione di lettura, per esempio passare da geografia a prodotto o da azienda a molecola con un unico asset riusabile.

## Requisiti

Il consumer deve avere almeno quattro colonne categoriali bindabili. Il modulo oggi e pensato per colonne descrittive, non per misure.

## Quando non utilizzarlo

Non usarlo se ti serve cambiare una misura: in quel caso il pattern giusto e `switch_measure_mvp`.

Non usarlo se ti serve un numero variabile di dimensioni generate al volo: questo MVP espone quattro binding fissi.

## Installazione rapida

1. esegui `suggest-bindings` e salva il profilo di binding
2. esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
