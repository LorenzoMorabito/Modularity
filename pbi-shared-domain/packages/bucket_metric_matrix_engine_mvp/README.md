# Bucket Metric Matrix Engine MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI un motore semantico per costruire una matrice overview con due famiglie di KPI organizzate nella stessa logica di lettura.

Non installa una pagina report pronta: prepara il layer dati da usare in bundle o report custom.

## Cosa fa

Il modulo standardizza la struttura di una matrix che deve mostrare due gruppi di KPI in modo coerente, per esempio valore, quota, QoQ e YoY per una famiglia primaria e per una famiglia secondaria.

In pratica evita di ricreare ogni volta la stessa struttura colonne e la stessa logica di visualizzazione per viste comparative complesse.

## Cosa fornisce

- la tabella visibile `MOD Bucket Matrix`
- la tabella tecnica `_MOD Bucket Matrix Structure`
- una struttura pronta per matrici overview con due famiglie di KPI
- un motore combinabile con altri package di bucketing o legend

## Quando utilizzarlo

Usalo quando vuoi costruire una matrix compatta che metta a confronto due gruppi di KPI nella stessa vista, mantenendo un layout coerente.

E adatto a casi come:

- overview comparative con doppia famiglia di metriche
- matrix target vs market da completare con altri engine
- bundle custom che richiedono una struttura colonne stabile

## Requisiti

Per usarlo correttamente servono:

- quattro misure per la famiglia primaria
- quattro misure per la famiglia secondaria
- una definizione chiara di quali KPI rappresentano valore, quota, QoQ e YoY

## Quando non utilizzarlo

Non e il modulo giusto se:

- ti serve una logica completa `Target / Top N / Others`
- vuoi una pagina report pronta da usare subito
- devi mostrare una sola famiglia di KPI e non una matrix a doppio blocco

## Installazione rapida

1. esegui `suggest-bindings` e associa le otto misure richieste alle due famiglie KPI
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
