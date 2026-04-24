# Documentazione tecnica e modello concettuale

## Obiettivo del modello

Il database è stato progettato per centralizzare le informazioni necessarie alla catalogazione di asset, servizi, dipendenze da fornitori terzi e responsabilità organizzative. La finalità è disporre di una base dati coerente e interrogabile, utile alla produzione di estrazioni strutturate per la compilazione di sezioni del profilo ACN in ambito NIS2.

Il modello evita la gestione dispersa delle informazioni in fogli di calcolo o documenti separati e introduce un registro unico, nel quale ogni elemento è collegato alle altre entità tramite relazioni esplicite e vincoli di integrità.

## Modello concettuale

Il modello si basa sulle seguenti aree informative:

- organizzazioni e unità organizzative;
- referenti e punti di contatto;
- asset aziendali;
- servizi erogati;
- relazioni tra servizi e asset;
- dipendenze da fornitori terzi;
- responsabilità su asset e servizi;
- storico delle modifiche tramite audit log.

Il diagramma ER è disponibile nei seguenti file:

- `docs/diagrams/er_diagram.png`
- `docs/diagrams/er_diagram.svg`
- `docs/diagrams/er_diagram.dot`

## Relazioni principali

L'entità centrale è `organization`, dalla quale dipendono business unit, contatti, asset, servizi, responsabilità e dipendenze. Questa scelta consente di gestire anche più organizzazioni nello stesso database, mantenendo la separazione logica dei dati tramite chiavi esterne.

La tabella `service_asset` realizza la relazione molti-a-molti tra servizi e asset. Un servizio può dipendere da più asset e lo stesso asset può supportare più servizi. La tabella ponte consente inoltre di specificare il ruolo dell'asset nel servizio e se l'asset è obbligatorio per l'erogazione.

Le dipendenze da terze parti sono gestite nella tabella `supplier_dependency`, collegata a `supplier` e, quando necessario, a un asset, a un servizio o a entrambi. In questo modo è possibile rappresentare sia dipendenze infrastrutturali, ad esempio cloud o connettività, sia dipendenze applicative o di supporto.

Le responsabilità sono modellate tramite `responsibility_assignment`. Ogni assegnazione collega un referente a un asset oppure a un servizio. Un vincolo `CHECK` impedisce che la stessa responsabilità sia riferita contemporaneamente a entrambi gli oggetti, mantenendo chiara la semantica del record.

## Normalizzazione

Lo schema è stato progettato seguendo i principi della terza forma normale. Le informazioni anagrafiche sono separate dalle relazioni operative, riducendo ridondanze e anomalie di aggiornamento.

Le principali scelte di normalizzazione sono:

- separazione tra `organization`, `business_unit` e `contact_person`;
- separazione tra `asset` e `service`, poiché rappresentano concetti diversi;
- uso di `service_asset` per gestire una relazione molti-a-molti;
- uso di `supplier` come anagrafica unica dei fornitori;
- uso di `supplier_dependency` per descrivere il contesto specifico della dipendenza;
- uso di `responsibility_assignment` per collegare persone, ruoli e oggetti di responsabilità.

Questa organizzazione permette di aggiornare un'informazione in un solo punto. Ad esempio, l'indirizzo email di un fornitore viene memorizzato nella tabella `supplier` e non ripetuto in ogni dipendenza.

## Vincoli di integrità

Per garantire la qualità del dato sono stati introdotti diversi vincoli:

- chiavi primarie su tutte le tabelle principali;
- chiavi esterne per garantire coerenza tra organizzazioni, asset, servizi, fornitori e referenti;
- vincoli `UNIQUE` per evitare duplicazioni di codici interni e identificativi fiscali;
- vincoli `CHECK` per controllare periodi di validità, valori ammessi e coerenza delle responsabilità;
- tipi enumerativi per campi con dominio chiuso, come criticità, tipologia asset, tipologia dipendenza e ruolo di responsabilità.

Sono stati inoltre creati indici sulle colonne più usate nelle interrogazioni, in particolare organizzazione, criticità, servizi critici, fornitori e audit log.

## Storico e versioning

Lo schema utilizza due meccanismi complementari:

1. campi di validità logica (`valid_from`, `valid_to`, `is_current`), utili per distinguere la versione corrente da registrazioni storiche;
2. tabella `audit_log`, popolata automaticamente da trigger, per registrare inserimenti, modifiche e cancellazioni.

La funzione `set_updated_at()` aggiorna automaticamente il campo `updated_at` quando un record viene modificato. La funzione `write_audit_log()` registra nella tabella `audit_log` l'operazione effettuata, il timestamp, l'utente database e la rappresentazione JSONB dei dati precedenti e successivi.

Questa soluzione consente di ricostruire le modifiche effettuate nel tempo e supporta esigenze di controllo, verifica e accountability.

## Trade-off progettuali

La normalizzazione rende il modello più coerente e riduce la duplicazione dei dati, ma richiede query con più join per ottenere viste operative complete. Per ridurre questa complessità è stata introdotta, nel punto 2, la view `v_acn_profile_csv`, che centralizza la logica di estrazione per l'output CSV.

È stato scelto l'uso di UUID come chiavi primarie per rendere gli identificativi indipendenti dal contesto applicativo e più adatti a scenari di integrazione o importazione dati. Il trade-off è una minore leggibilità rispetto a identificativi numerici progressivi, compensata dalla presenza di codici funzionali come `asset_code` e `service_code`.

I tipi enumerativi migliorano la qualità del dato perché limitano i valori ammessi. Lo svantaggio è che eventuali nuove categorie richiedono una modifica controllata dello schema. In questo progetto la scelta è stata considerata accettabile perché le classificazioni principali sono relativamente stabili e rilevanti per la coerenza delle estrazioni.

Il sistema di audit tramite JSONB conserva una fotografia completa dei record modificati. Questo approccio è flessibile e non richiede tabelle storiche dedicate per ogni entità, ma rende meno immediata l'interrogazione analitica dello storico rispetto a un modello temporale completamente normalizzato.

## File prodotti

La documentazione del punto 3 è composta da:

- `docs/technical_documentation.md`: descrizione tecnica del modello, normalizzazione, trade-off e storico;
- `docs/data_dictionary.md`: dizionario dati di tabelle e campi;
- `docs/deploy.md`: istruzioni operative per installazione, caricamento dati ed esportazione;
- `docs/diagrams/er_diagram.png`: diagramma ER in formato immagine;
- `docs/diagrams/er_diagram.svg`: versione vettoriale del diagramma;
- `docs/diagrams/er_diagram.dot`: sorgente Graphviz del diagramma.
