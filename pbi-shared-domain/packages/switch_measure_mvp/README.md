# Switch Measure MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa un selettore semantico di misure che permette di cambiare KPI in un visual senza duplicare chart o pagine.

## Cosa fa

Installa una tabella visibile con le metriche selezionabili e una tabella tecnica di input che riceve le misure bindate dal consumer.

## Cosa fornisce

Fornisce la facade `MOD Switch Measure`, la tabella tecnica `_MOD Switch Measure Inputs` e 2 binding guidati verso le misure del modello target.

## Quando utilizzarlo

Usalo quando vuoi lasciare all'utente la scelta tra piu misure mantenendo la stessa struttura visuale.

## Requisiti

Il package richiede due misure nel consumer da associare ai binding guidati del modulo.

## Quando non utilizzarlo

Non usarlo se ti serve cambiare una dimensione categoriale o un field parameter: questo modulo lavora solo sullo switch tra misure.

## Installazione rapida

1. esegui `suggest-bindings` e salva il profilo di binding
2. esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, limiti V1 e asset installati usare anche `PACKAGE.md`.
