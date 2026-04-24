# Dataset simulato e verifiche

Il dataset simulato è stato predisposto per validare il comportamento dello schema relazionale e delle query di esportazione senza accedere a sistemi o dati aziendali reali.

Il file `sql/05_test_dataset.sql` aggiunge una seconda organizzazione fittizia rispetto al dataset iniziale. Questa scelta consente di verificare non solo la presenza dei dati, ma anche il corretto funzionamento del filtro per singola azienda previsto dalla funzione `fn_acn_profile_csv()`.

Il dataset include organizzazioni appartenenti a settori differenti, business unit responsabili dei servizi digitali, contatti interni con ruoli organizzativi distinti, fornitori terzi con contatti di supporto e sicurezza, asset applicativi e infrastrutturali classificati per criticità, servizi critici con parametri RTO e RPO, dipendenze contrattuali verso fornitori esterni e responsabilità assegnate a referenti aziendali.

Il file `tests/01_run_validation.sql` contiene controlli automatici realizzati direttamente in PostgreSQL tramite blocchi `DO`. I controlli verificano che le entità minime siano presenti e che la view e la funzione CSV producano risultati. In caso di esito negativo viene generata un'eccezione, rendendo evidente l'errore durante l'esecuzione.

Il file `tests/02_export_csv_examples.sql` contiene i comandi `\copy` per generare file CSV dimostrativi nella cartella `export/`.
