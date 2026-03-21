# Competitive Benchmark Bundle MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI un motore semantico per benchmark competitivo, pensato per confrontare player, brand o altre entita usando piu metriche e preset scatter.

Non installa una report page pronta. Prepara invece la logica riusabile per costruire viste benchmark e posizionamento competitivo.

## Cosa fa

Il modulo permette di definire preset di confronto, per esempio asse X, asse Y e dimensione dei punti, e di offrire all'utente un selettore di metriche benchmark.

Questo rende piu semplice costruire scatter o viste comparative dove il focus non e solo il ranking, ma il posizionamento relativo tra entita concorrenti.

## Cosa fornisce

- la tabella visibile `MOD Competitive Benchmark`
- tabelle tecniche per input, metriche e preset
- una base riusabile per scatter benchmark e confronti competitivi
- un selettore di metriche benchmark gia predisposto

## Quando utilizzarlo

Usalo quando vuoi analizzare il posizionamento competitivo tra player o brand su piu assi di lettura.

E adatto a casi come:

- scatter benchmark
- confronti brand vs competitor
- analisi di posizionamento basate su piu metriche

## Requisiti

Per usarlo bene servono:

- misure adatte a essere usate come asse X, asse Y e size nei preset
- almeno una misura nel selettore benchmark
- un consumer dove il confronto competitivo abbia senso dal punto di vista business

## Quando non utilizzarlo

Non e il modulo giusto se:

- ti serve solo una classifica Top N
- non hai metriche adatte a un benchmark multiasse
- vuoi una pagina report gia pronta senza costruzione visuale successiva

## Installazione rapida

1. esegui `suggest-bindings` e configura i preset benchmark e il set di misure del selettore
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
