# Bucket Metric Family Bundle MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI una struttura semantica riusabile per confrontare una entita target con i principali competitor e con il resto del mercato.

Non crea un report pronto all'uso. Aggiunge nel modello la logica di confronto `Target / Top N / Others` da usare poi nei report del consumer.

## Cosa fa

Il modulo divide automaticamente una dimensione di business, per esempio `Brand`, `Cliente`, `Prodotto` o `Retailer`, in tre gruppi logici:

- `Target`
- `Top N`
- `Others`

Su questi gruppi calcola KPI gia pronti come valore corrente, quota, confronto trimestre su trimestre, confronto anno su anno ed `EI`.

## Cosa fornisce

- la tabella visibile `MOD Bucket Family`
- tabelle tecniche per target, Top N, slots e legenda
- una logica riusabile per confrontare `Target`, `Top N` e `Others`
- KPI pronti come `Current Value`, `Share`, `QoQ%`, `YoY%` ed `EI`

## Quando utilizzarlo

Usalo quando vuoi confrontare una entita specifica con i competitor principali e con il resto del mercato senza costruire la logica DAX da zero.

E adatto a casi come:

- benchmark competitivo
- letture target vs mercato
- analisi di quota e crescita per cluster di entita

## Requisiti

Per usarlo correttamente servono:

- una dimensione da analizzare
- una misura di ranking
- una misura corrente
- una misura di confronto trimestre precedente
- una misura di confronto anno precedente
- una misura totale corrente
- una misura totale anno precedente

## Quando non utilizzarlo

Non e il modulo giusto se:

- vuoi un confronto fisso e manuale tra pochi competitor
- non hai le misure base richieste
- ti aspetti una pagina report pronta senza dover costruire il layer visuale

## Installazione rapida

1. esegui `suggest-bindings` e associa dimensione, ranking, valore corrente, riferimenti periodo e misure total
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
