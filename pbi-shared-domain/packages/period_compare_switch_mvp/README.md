# Period Compare Switch MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI un selettore riusabile per passare da un confronto di breve periodo a un confronto rolling piu ampio.

Serve a standardizzare il cambio di orizzonte analitico senza dover riscrivere ogni volta misure e logiche di visualizzazione.

## Cosa fa

Il modulo mette a disposizione una logica che sceglie tra due coppie di misure:

- corrente e riferimento per orizzonte breve
- corrente e riferimento per orizzonte rolling

Da questa scelta ricava anche delta e delta percentuale, cosi lo stesso visual puo cambiare modalita di lettura in modo coerente.

## Cosa fornisce

- la tabella visibile `MOD Period Compare`
- una logica pronta per switch breve vs rolling
- output riusabili per current, reference, delta e delta percent

## Quando utilizzarlo

Usalo quando vuoi far scegliere all'utente se leggere il KPI su un periodo breve o su un periodo piu ampio senza cambiare pagina o visual.

E adatto a casi come:

- confronto mese vs anno mobile
- short term vs long term performance
- analisi dove il concetto di confronto cambia ma la UX deve restare stabile

## Requisiti

Per usarlo correttamente servono:

- una misura corrente short term
- una misura riferimento short term
- una misura corrente rolling
- una misura riferimento rolling

## Quando non utilizzarlo

Non e il modulo giusto se:

- hai un solo orizzonte di confronto
- non hai gia disponibili le quattro misure richieste
- ti serve un compare multi-metrica piu articolato

## Installazione rapida

1. esegui `suggest-bindings` e associa le due coppie di misure short e rolling
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
