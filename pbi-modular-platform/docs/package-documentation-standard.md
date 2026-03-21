# Package Documentation Standard

Ogni package installabile deve contenere entrambi i file locali:

- `README.md`
- `PACKAGE.md`

## Obiettivo

La documentazione del package deve permettere di capire rapidamente:

- cosa fa il modulo in linguaggio business
- quando usarlo e quando no
- cosa si sta installando nel consumer
- quali binding o parametri servono
- quali limiti dichiarati ha
- come validarlo, installarlo e testarlo correttamente

## Contratto documentale

### README.md

`README.md` e la scheda descrittiva rapida del pack. Per i nuovi package generati via scaffold deve seguire il template business standard con queste sezioni:

- Cos'e questo modulo
- Cosa fa
- Cosa fornisce
- Quando utilizzarlo
- Requisiti
- Quando non utilizzarlo
- Installazione rapida

Per i file marcati come standardizzati, l'ordine delle sezioni e parte del contratto e viene verificato dai quality checks.

### PACKAGE.md

`PACKAGE.md` e la scheda installativa operativa del pack. Deve contenere almeno queste sezioni:

- Identita
- Caratteristiche
- Cosa installa
- Prerequisiti dichiarati
- Parametri di binding
- Cosa non fa
- Installazione corretta
- Uso consigliato
- File del package

Per `PACKAGE.md` la sequenza delle sezioni `##` e parte del layout approvato e viene verificata dai quality checks.

## Regola di enforcement

Il contratto non e solo documentale:

- `new-module` genera automaticamente `README.md` e `PACKAGE.md` standardizzati
- `test-module` e `test-repo` falliscono se mancano i file obbligatori
- `test-module` e `test-repo` falliscono se i file generati dallo scaffold contengono ancora placeholder o TODO
- `PACKAGE.md` deve sempre mantenere le sezioni minime richieste
- il layout standard dei file documentali viene controllato in modo esplicito dai quality checks

## Regola di aggiornamento

Quando cambiano `manifest.json`, asset semantic, asset report o comportamento installativo del package, aggiornare anche `README.md` e `PACKAGE.md` nello stesso change set.

## Convenzione operativa

- `README.md` resta business-facing e leggibile da chi deve capire se il pack e adatto al caso d'uso
- `PACKAGE.md` resta installativo e operativo, con binding, limiti, asset e sequenza corretta di comandi
- i dettagli tecnici possono essere raffinati manualmente, ma il perimetro minimo non puo essere rimosso
