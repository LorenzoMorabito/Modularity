# Finance Compare MVP

<!-- PBI_PACKAGE_README_STANDARD_V1 -->

## Cos'e questo modulo

Questo modulo installa nel modello Power BI un componente riusabile per confrontare una metrica principale con due metriche di riferimento lungo un asse temporale.

Non si limita a creare singole misure di supporto: aggiunge anche una pagina report starter per validare subito il confronto nel consumer.

## Cosa fa

Il modulo permette di leggere una metrica corrente, per esempio `ACT`, e confrontarla con due riferimenti selezionabili, per esempio `BDG` e `PY`.

Calcola la differenza assoluta, la differenza percentuale e la lettura nel tempo sul periodo scelto, cosi da avere un blocco compare pronto da riusare.

## Cosa fornisce

- la tabella visibile `MOD Finance Compare`
- tabelle tecniche di supporto per input e selettore confronto
- una pagina report starter `Metric Compare`
- una logica pronta per confronti tipo actual vs budget e actual vs previous year

## Quando utilizzarlo

Usalo quando vuoi costruire rapidamente un confronto semplice e leggibile tra una misura principale e due benchmark di riferimento sul tempo.

E adatto a casi come:

- confronto finance `ACT vs BDG vs PY`
- controllo scostamenti mensili o trimestrali
- KPI compare con trend temporale minimo gia pronto

## Requisiti

Per usarlo correttamente servono:

- una misura principale
- due misure di riferimento
- una colonna temporale ordinata da usare come asse

## Quando non utilizzarlo

Non e il modulo giusto se:

- vuoi confrontare molte metriche diverse nella stessa vista
- non hai un asse temporale coerente
- ti serve un report finale gia rifinito per l'utente business

## Installazione rapida

1. esegui `suggest-bindings` e associa misura principale, riferimento 1, riferimento 2 e asse temporale
2. salva il profilo di binding ed esegui `validate`
3. esegui `install`
4. esegui `test`

Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.
