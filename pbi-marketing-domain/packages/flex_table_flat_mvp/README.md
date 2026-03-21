# Flex Table Flat MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI una tabella flat riusabile e configurabile, pensata per mostrare dimensioni e misure come normali colonne di output.

Aggiunge la logica semantica e una pagina report starter, ma non impone un layout rigido definitivo.

## Cosa fa

Il modulo permette di selezionare quali colonne descrittive e quali metriche mostrare in una tabella piatta.

Il risultato e una vista piu semplice e piu vicina a un export analitico rispetto alla versione pivot, perche le dimensioni non vengono raggruppate come livelli di riga ma esposte come colonne standard.

## Cosa fornisce

- la tabella visibile `MOD Flex Flat`
- tabelle tecniche per selezione dimensioni e misure
- una pagina report starter `Flexible Flat Table`
- una struttura pronta per tabelle flat, letture di dettaglio e output piu esportabili

## Quando utilizzarlo

Usalo quando vuoi una tabella leggibile, piatta e configurabile, dove l'utente possa scegliere quali colonne e KPI vedere senza passare da una logica pivot.

E adatto a casi come:

- viste di dettaglio prodotto o cliente
- tabelle operative da filtrare e esportare
- analisi dove le dimensioni devono restare colonne normali

## Requisiti

Per usarlo bene servono:

- un consumer con piu colonne descrittive utili
- un set di misure utili da rendere selezionabili
- almeno una dimensione e una misura scelte durante il binding

## Quando non utilizzarlo

Non e il modulo giusto se:

- vuoi una matrice o una tabella pivot con gruppi di riga
- ti serve una logica competitiva o di benchmark
- hai un layout completamente fisso e non ti serve selezione utente

## Installazione rapida

1. esegui `suggest-bindings` e scegli colonne descrittive e misure da esporre
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
