# Project Work NIS2/ACN - Asset Registry

Repository dimostrativo per la progettazione di una base dati relazionale finalizzata alla catalogazione di asset, servizi, dipendenze da fornitori terzi e responsabilità organizzative utili alla produzione di estrazioni strutturate in ambito NIS2/ACN.

## Struttura del repository

```text
nis2-acn-asset-registry/
├── README.md
├── sql/
│   ├── 01_schema.sql
│   ├── 02_seed.sql
│   ├── 03_verify.sql
│   └── 04_acn_csv_export.sql
├── docs/
│   ├── technical_documentation.md
│   ├── data_dictionary.md
│   ├── deploy.md
│   └── diagrams/
│       ├── er_diagram.png
│       ├── er_diagram.svg
│       └── er_diagram.dot
└── export/
```

## Requisiti

- PostgreSQL 15 o superiore
- Client `psql`
- Estensione PostgreSQL `pgcrypto`

## Installazione rapida

```bash
createdb nis2_registry_demo
psql -d nis2_registry_demo -f sql/01_schema.sql
psql -d nis2_registry_demo -f sql/02_seed.sql
psql -d nis2_registry_demo -f sql/04_acn_csv_export.sql
psql -d nis2_registry_demo -f sql/03_verify.sql
```

## Contenuto degli script SQL

- `01_schema.sql`: crea schema PostgreSQL, tabelle, tipi enumerativi, vincoli, indici, funzioni e trigger di audit.
- `02_seed.sql`: inserisce dati simulati rappresentativi.
- `03_verify.sql`: contiene query di controllo per verificare caricamento e relazioni principali.
- `04_acn_csv_export.sql`: contiene query di estrazione, view `v_acn_profile_csv` e funzione `fn_acn_profile_csv()` per export CSV.

## Documentazione

La documentazione tecnica si trova nella cartella `docs/`:

- `technical_documentation.md`: descrizione del modello, normalizzazione, trade-off e gestione dello storico.
- `data_dictionary.md`: descrizione di tabelle, campi, vincoli e significato dei dati.
- `deploy.md`: istruzioni operative per deploy, verifica ed esportazione CSV.
- `diagrams/er_diagram.png`: diagramma ER in formato immagine.
- `diagrams/er_diagram.svg`: diagramma ER in formato vettoriale.
- `diagrams/er_diagram.dot`: sorgente Graphviz del diagramma.

## Esportazione CSV

Per esportare il profilo di una singola azienda:

```bash
mkdir -p export
psql -d nis2_registry_demo -c "\copy (SELECT * FROM nis2_registry.fn_acn_profile_csv('12345678901')) TO 'export/acn_profile_azienda_digitale.csv' WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');"
```

Per esportare l'intera view:

```bash
mkdir -p export
psql -d nis2_registry_demo -c "\copy (SELECT * FROM nis2_registry.v_acn_profile_csv ORDER BY azienda, codice_servizio, codice_asset) TO 'export/acn_profile_all.csv' WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');"
```

## Test e dataset simulato

Per verificare il funzionamento senza usare dati reali è disponibile un dataset aggiuntivo e una suite di controlli SQL.

```bash
psql -d nis2_registry_demo -f sql/05_test_dataset.sql
psql -d nis2_registry_demo -f tests/01_run_validation.sql
psql -d nis2_registry_demo -f tests/02_export_csv_examples.sql
```

Gli script di test controllano che siano presenti organizzazioni, asset critici, servizi, dipendenze, responsabilità e righe esportabili tramite la view `v_acn_profile_csv` e la funzione `fn_acn_profile_csv()`.
