# PBI Shared Domain

Area di dominio per i package semantic generalisti e cross-schema.

## Contenuti

- `catalog/`
  registro dei package shared disponibili
- `packages/`
  source of truth dei package riusabili tra domini diversi

## Obiettivo

Questa area raccoglie i package derivati da logiche reusable che non devono dipendere da naming o schema specifici `finance`, `sales` o `promo`.

Ogni package installabile della cartella `packages/` include una scheda `PACKAGE.md` per funzionalita, binding, limiti e installazione corretta.

## Installabili disponibili

I package installabili oggi disponibili nel dominio `shared` sono `13`. Questa lista serve come indice rapido per capire quale pack cercare in base al bisogno dell'utente.

Le descrizioni qui sotto sono volutamente in linguaggio business. I dettagli tecnici di binding, prerequisiti e limiti restano nelle singole schede `PACKAGE.md`.

**`bucket_metric_family_bundle_mvp` `0.1.0`**

Serve per dividere un elenco di entita, per esempio prodotti, clienti o brand, in fasce e confrontare per ogni fascia il valore attuale con i periodi precedenti.

**`bucket_metric_matrix_engine_mvp` `0.1.0`**

Serve per costruire una matrice di confronto tra due gruppi di KPI, organizzati per fasce, quando vuoi leggere piu misure insieme in una vista compatta.

**`bucket_slot_legend_engine_mvp` `0.1.0`**

Serve per assegnare ogni entita a una fascia e mostrarne la legenda in modo coerente, utile quando vuoi classificare elementi in cluster o segmenti leggibili.

**`bucketed_overview_matrix_bundle_mvp` `0.1.0`**

E un pacchetto piu completo per creare una vista riepilogativa con fasce, confronti KPI e pagina report gia pronta, utile per partire piu velocemente su un caso di analisi completo.

**`competitive_benchmark_bundle_mvp` `0.1.0`**

Serve per confrontare player, brand o altre entita concorrenti usando piu metriche, con una struttura adatta a benchmark e posizionamento competitivo.

**`kpi_delta_signal_mvp` `0.1.0`**

Serve per mostrare se un KPI sta migliorando o peggiorando, con etichetta e colore coerenti, per esempio verde se sale e rosso se scende.

**`lag_correlation_explorer_mvp` `0.1.0`**

Serve per capire se una misura influenza un'altra con ritardo nel tempo, per esempio se un investimento oggi produce effetto sulle vendite dopo alcune settimane o mesi.

**`metric_switch_selector_mvp` `0.1.0`**

Serve per dare all'utente la possibilita di scegliere quale metrica visualizzare, per esempio passare da vendite a volume o quota con un selettore unico.

**`period_compare_switch_mvp` `0.1.0`**

Serve per passare rapidamente tra confronti di breve periodo e confronti piu ampi, per esempio mese vs anno mobile, senza cambiare logica di lettura del KPI.

**`spend_bucket_pareto_mvp` `0.1.0`**

Serve per separare le entita in gruppi tipo top spender, fascia intermedia e coda lunga, cosi da capire chi pesa davvero sulla spesa totale.

**`topn_target_driver_bundle_mvp` `0.2.0`**

Serve per mostrare le top entita in base a una metrica scelta, con possibilita di cambiare criterio di classifica e con una pagina report gia pronta per iniziare.

**`switch_measure_mvp` `0.1.0`**

Serve per lasciare all'utente la scelta della misura da visualizzare, per esempio passare da Sales a Units con un selettore unico gia pronto nel modello.

**`switch_dimension_mvp` `0.1.0`**

Serve per lasciare all'utente la scelta della dimensione categoriale da usare nei visual, per esempio passare da Country a Corporation, Product o Molecule con un field parameter gia installabile.

## Package presenti ma non installabili

**`kpi_delta_format_pack_mvp`**

E presente nella cartella `packages/` come riferimento storico, ma non espone `manifest.json` e quindi non e un installabile del framework modulare.
