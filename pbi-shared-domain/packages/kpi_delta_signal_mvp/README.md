# KPI Delta Signal MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI un helper semantico leggero per trasformare una misura delta in un segnale leggibile con label, freccia e colore.

E un micro-package pensato per standardizzare il modo in cui i delta KPI vengono mostrati nei report.

## Cosa fa

Il modulo prende una misura delta e la classifica come positiva, negativa o neutra.

Da questa logica ricava una label formattata e un colore coerente da usare in card, KPI, small multiples o conditional formatting.

## Cosa fornisce

- la tabella visibile `MOD KPI Signal`
- una logica riusabile per label e colore del delta
- un componente semplice da collegare a card e KPI esistenti

## Quando utilizzarlo

Usalo quando vuoi rendere uniforme la lettura dei delta nei report e non vuoi ricostruire ogni volta freccia, colore e semaforizzazione.

E adatto a casi come:

- KPI di crescita o calo
- confronto vs previous year
- visual con conditional formatting standardizzata

## Requisiti

Per usarlo correttamente serve:

- una misura delta o percentuale delta gia disponibile nel consumer

## Quando non utilizzarlo

Non e il modulo giusto se:

- ti serve una logica completa di confronto tra periodi
- non hai gia una misura delta affidabile
- ti aspetti una pagina report o un benchmark completo

## Installazione rapida

1. esegui `suggest-bindings` e associa la misura delta
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
