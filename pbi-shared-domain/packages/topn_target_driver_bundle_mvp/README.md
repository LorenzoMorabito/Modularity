# TopN Target Driver Bundle MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI un bundle riusabile per analisi Top N, ranking dinamico e target entity, con una pagina report starter gia inclusa.

E pensato per dare all'utente il controllo su quale dimensione ordinare, con quale metrica e con quale target mantenere il focus.

## Cosa fa

Il modulo permette di:

- scegliere il grain da ordinare
- scegliere la metrica di ranking
- selezionare opzionalmente una entita target
- definire il valore di `Top N`

Su questa base costruisce il set Top N risultante e rende disponibile una pagina report tecnica per testare subito il comportamento.

## Cosa fornisce

- la tabella visibile `MOD TopN Driver`
- tabelle tecniche per input, grains, metriche, target e valore Top N
- una pagina report starter `TopN Target Driver`
- una logica riusabile per ranking dinamico e focus su target entity

## Quando utilizzarlo

Usalo quando vuoi un modulo flessibile per classifiche dinamiche, analisi top entity e confronto con un target scelto dall'utente.

E adatto a casi come:

- top brand o top prodotti
- ranking dinamico per metrica
- analisi target vs top set

## Requisiti

Per usarlo bene servono:

- una o piu dimensioni candidate a essere ordinate
- una o piu misure candidate per il ranking
- almeno una dimensione e una misura scelte durante il binding

## Quando non utilizzarlo

Non e il modulo giusto se:

- la classifica e fissa e non deve essere scelta dall'utente
- non ti serve una logica target o Top N dinamica
- vuoi solo una semplice tabella statica senza controlli utente

## Installazione rapida

1. esegui `suggest-bindings` e scegli le dimensioni e le misure da usare per il ranking
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
