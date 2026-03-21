# Flex Metrics Table MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI una tabella pivot riusabile e configurabile, pensata per analisi esplorative dove l'utente deve poter scegliere dimensioni e metriche da mostrare.

Aggiunge sia la logica semantica sia una pagina report starter per verificare subito il comportamento del modulo.

## Cosa fa

Il modulo permette di costruire una tabella flessibile in stile pivot, con selezione delle righe e delle metriche tramite slicer.

Le dimensioni possono essere cambiate senza rifare il report da zero, e le metriche possono essere combinate nello stesso oggetto per ottenere una vista analitica piu ampia.

## Cosa fornisce

- la tabella visibile `MOD Flex Pivot`
- tabelle tecniche per input, selettore metriche e asse righe
- una pagina report starter `Flexible Metrics Pivot`
- una struttura pronta per tabelle pivot multi-dimensione e multi-metrica

## Quando utilizzarlo

Usalo quando vuoi dare all'utente una tabella unica da esplorare cambiando dimensioni e KPI senza dover mantenere molte pagine quasi uguali.

E adatto a casi come:

- analisi prodotto, paese, corporation o quarter nella stessa esperienza
- confronto di vendite, volumi, promo e finance in una vista unica
- tabelle operative per analisi dettagliata e navigazione libera

## Requisiti

Per usarlo bene servono:

- un consumer con piu dimensioni utili da esporre come righe
- un set di misure utili da rendere selezionabili
- almeno una dimensione e una misura scelte durante il binding

## Quando non utilizzarlo

Non e il modulo giusto se:

- vuoi una tabella piatta da export o copia-incolla diretto
- hai un layout fisso e non vuoi lasciare scelta all'utente
- ti serve solo un piccolo blocco KPI e non una tabella analitica

## Installazione rapida

1. esegui `suggest-bindings` e scegli il set di dimensioni e misure da esporre
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
