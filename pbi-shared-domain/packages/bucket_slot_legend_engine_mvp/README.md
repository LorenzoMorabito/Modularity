# Bucket Slot Legend Engine MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI un motore semantico per classificare le entita in gruppi logici e produrre una legenda coerente per usarli nei report.

Non crea un report pronto. Fornisce il layer base per viste competitive o segmentate che devono riusare la stessa logica di bucketing.

## Cosa fa

Il modulo prende una dimensione, una misura di valore e una misura di ranking e costruisce una logica `Target / Top N / Others` con relativa legenda.

Serve quindi a stabilire chi entra nel target, chi nei top competitor e chi finisce nel gruppo aggregato `Others`, mantenendo il tutto aggiornato quando cambiano i dati.

## Cosa fornisce

- la tabella visibile `MOD Bucket Slots`
- tabelle tecniche per input, target, Top N, slots e legenda
- una logica riusabile di classificazione competitiva
- un layer comune da usare in report, matrix o chart custom

## Quando utilizzarlo

Usalo quando vuoi costruire viste competitive o segmentate che devono condividere la stessa logica di gruppo tra piu visual.

E adatto a casi come:

- classificazione target vs competitor
- legenda coerente per visual bucketed
- base tecnica per bundle successivi piu ricchi

## Requisiti

Per usarlo correttamente servono:

- una dimensione da classificare
- una misura di valore
- una misura di ranking

## Quando non utilizzarlo

Non e il modulo giusto se:

- vuoi gia anche KPI avanzati come share, QoQ, YoY o EI
- ti serve una report page pronta
- non hai bisogno di una logica dinamica `Target / Top N / Others`

## Installazione rapida

1. esegui `suggest-bindings` e associa dimensione, misura di valore e misura di ranking
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
