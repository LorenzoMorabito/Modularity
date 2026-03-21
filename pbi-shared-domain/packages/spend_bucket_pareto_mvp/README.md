# Spend Bucket Pareto MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI una logica Pareto riusabile per segmentare una dimensione in base alla spesa o a una misura assimilabile.

Non crea un report pronto, ma aggiunge un layer semantico utile per analizzare contributo, concentrazione e coda lunga.

## Cosa fa

Il modulo ordina le entita in base alla spesa, ne calcola il contributo cumulato e le assegna a bucket di lettura tipo top spender, fascia intermedia e resto.

Questo permette di capire rapidamente chi pesa davvero sul totale e quanto e concentrata la spesa.

## Cosa fornisce

- la tabella visibile `MOD Spend Buckets`
- la tabella tecnica `_MOD Spend Buckets`
- bucket Pareto gia pronti
- misure riusabili per rank, quota e valore per bucket

## Quando utilizzarlo

Usalo quando vuoi leggere la concentrazione della spesa o del valore su una dimensione di business.

E adatto a casi come:

- top spender vs long tail
- analisi di concentrazione promo o investimento
- segmentazione entita per contributo al totale

## Requisiti

Per usarlo correttamente servono:

- una dimensione da analizzare
- una misura di spesa o valore equivalente

## Quando non utilizzarlo

Non e il modulo giusto se:

- non hai una logica Pareto da applicare
- la misura disponibile non rappresenta un valore cumulabile utile per ranking
- vuoi una pagina report gia pronta senza authoring successivo

## Installazione rapida

1. esegui `suggest-bindings` e associa dimensione e misura di spesa
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
