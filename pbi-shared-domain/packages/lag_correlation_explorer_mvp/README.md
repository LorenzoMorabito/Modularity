# Lag Correlation Explorer MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI un motore semantico per analizzare la relazione tra una misura driver e una misura risposta con possibili ritardi nel tempo.

Non crea una pagina report pronta, ma aggiunge la logica necessaria per studiare lag, correlazione e ritardo di effetto.

## Cosa fa

Il modulo mette a confronto una serie driver e una serie risposta su un asse temporale ordinato.

Permette di esplorare se l'effetto della misura driver si manifesta subito o con ritardo, e fornisce elementi utili per leggere il lag migliore e la relazione tra le due serie.

## Cosa fornisce

- la tabella visibile `MOD Lag Explorer`
- tabelle tecniche per input, lambda e max lag
- una base riusabile per analisi driver-response nel tempo
- logica pronta per studi di correlazione e ritardo

## Quando utilizzarlo

Usalo quando vuoi capire se una variabile, per esempio investimento o pressione promo, produce effetto su un'altra misura dopo alcune settimane o mesi.

E adatto a casi come:

- analisi marketing mix semplificata
- verifica ritardo tra driver e risultato
- studio di relazioni temporali tra due KPI

## Requisiti

Per usarlo correttamente servono:

- una misura driver
- una misura risposta
- una colonna temporale ordinata

## Quando non utilizzarlo

Non e il modulo giusto se:

- non hai serie temporali coerenti
- ti serve solo un confronto diretto senza ritardi
- vuoi una pagina report pronta senza authoring successivo

## Installazione rapida

1. esegui `suggest-bindings` e associa driver, risposta e asse temporale
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
