# Package Documentation Standard

Ogni package installabile deve contenere un file locale `PACKAGE.md` pensato per chi installa o valuta il modulo.

## Obiettivo

La documentazione del package deve permettere di capire rapidamente:

- cosa si sta installando nel consumer
- quali funzioni copre il package
- quali limiti dichiarati ha
- quali binding o parametri servono
- come validarlo, installarlo e testarlo correttamente
- come usarlo bene dopo l'installazione

## Sezioni minime

- Identita
- Caratteristiche
- Cosa installa
- Prerequisiti dichiarati
- Parametri di binding
- Cosa non fa
- Installazione corretta
- Uso consigliato
- File del package

## Regola di aggiornamento

Quando cambiano `manifest.json`, asset semantic, asset report o comportamento installativo del package, aggiornare anche `PACKAGE.md` nello stesso change set.

## Convenzione operativa

- il contenuto puo essere generato a partire dal manifest
- i dettagli specifici di UX o caveat di business possono essere raffinati manualmente
- il file `README.md` puo restare descrittivo o storico, mentre `PACKAGE.md` e la scheda installativa operativa