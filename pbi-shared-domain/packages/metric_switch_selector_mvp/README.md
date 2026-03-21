# Metric Switch Selector MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI un selettore riusabile di metriche, pensato per permettere all'utente di cambiare KPI senza duplicare visual e pagine.

Non aggiunge un report pronto, ma un layer semantico leggero e molto riusabile.

## Cosa fa

Il modulo costruisce una lista di metriche selezionabili e mette a disposizione il valore e la label della metrica scelta.

In questo modo puoi usare lo stesso visual per mostrare KPI diversi, lasciando all'utente la scelta di cosa vedere.

## Cosa fornisce

- la tabella visibile `MOD Metric Switch`
- la tabella tecnica `_MOD Metric Switch Inputs`
- una logica pronta per selettori di misura riusabili
- output utili per valore selezionato e label selezionata

## Quando utilizzarlo

Usalo quando vuoi evitare di duplicare visual quasi uguali per mostrare KPI diversi.

E adatto a casi come:

- switch tra vendite, volumi, quota o spesa
- pagine con un solo chart ma piu KPI possibili
- report dove l'utente deve cambiare metrica mantenendo la stessa UX

## Requisiti

Per usarlo correttamente serve:

- un insieme di misure candidate da esporre nel selettore
- almeno una misura scelta durante il binding

## Quando non utilizzarlo

Non e il modulo giusto se:

- il KPI da mostrare e sempre uno solo
- non vuoi lasciare scelta all'utente
- ti serve un benchmark o una logica competitiva, non solo uno switch di misura

## Installazione rapida

1. esegui `suggest-bindings` e scegli il set di misure da esporre nel selettore
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
