# Bucketed Overview Matrix Bundle MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI un bundle completo per costruire una overview competitiva basata su `Target / Top N / Others`, doppia famiglia di KPI e matrix pronta da validare.

Oltre alla logica semantica installa anche una pagina report starter, quindi e il pacchetto piu vicino a una soluzione pronta tra i moduli bucketed.

## Cosa fa

Il modulo combina in un unico package:

- selezione target
- logica Top N
- gruppo `Others`
- legenda
- doppia famiglia di KPI
- matrix overview
- pagina report iniziale

Permette quindi di partire subito con una vista competitiva completa, senza dover assemblare piu engine separati.

## Cosa fornisce

- la tabella visibile `MOD Bucket Overview`
- tabelle tecniche per input, target, Top N, slots, legenda e structure
- una pagina report starter `Bucketed Overview Matrix`
- una soluzione integrata per overview comparative a bucket

## Quando utilizzarlo

Usalo quando vuoi partire velocemente con una vista completa target vs competitor e non vuoi comporre manualmente piu package piccoli.

E adatto a casi come:

- overview competitive gia strutturate
- benchmark con due famiglie di KPI
- prototipi rapidi di pagine analysis complete

## Requisiti

Per usarlo correttamente servono:

- una dimensione da analizzare
- una misura di ranking
- la famiglia primaria di misure correnti, riferimenti periodo e totali
- la famiglia secondaria di misure correnti, riferimenti periodo e totali

## Quando non utilizzarlo

Non e il modulo giusto se:

- ti serve solo una parte del comportamento, per esempio solo legend o solo matrix
- vuoi una UX completamente custom e non una pagina starter
- non hai gia disponibili le famiglie KPI richieste

## Installazione rapida

1. esegui `suggest-bindings` e associa dimensione, ranking e le due famiglie complete di misure
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
