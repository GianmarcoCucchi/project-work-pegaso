# Data dictionary

Il data dictionary descrive le tabelle principali dello schema `nis2_registry`. I tipi enumerativi sono utilizzati per rendere omogenee le classificazioni ricorrenti e ridurre il rischio di valori non coerenti.

## Tipi enumerativi

| Tipo | Valori | Uso |
|---|---|---|
| `subject_type` | `ESSENZIALE`, `IMPORTANTE`, `NON_CLASSIFICATO` | Classificazione del soggetto/organizzazione. |
| `asset_type` | `SERVER`, `DATABASE`, `APPLICAZIONE`, `RETE`, `CLOUD`, `ENDPOINT`, `DISPOSITIVO_OT_IOT`, `ALTRO` | Tipologia dell'asset. |
| `criticality_level` | `BASSA`, `MEDIA`, `ALTA`, `CRITICA` | Livello di criticità o impatto. |
| `environment_type` | `PRODUZIONE`, `TEST`, `SVILUPPO`, `DR`, `ALTRO` | Ambiente operativo dell'asset. |
| `responsibility_role` | `OWNER`, `RESPONSABILE_TECNICO`, `RESPONSABILE_SICUREZZA`, `REFERENTE_BUSINESS`, `REFERENTE_FORNITORE`, `DPO`, `ALTRO` | Ruolo assegnato a un referente. |
| `dependency_type` | `HOSTING`, `CONNETTIVITA`, `SOFTWARE`, `MANUTENZIONE`, `SUPPORTO`, `CLOUD`, `DATI`, `ALTRO` | Natura della dipendenza da un fornitore. |
| `relation_type` | `DIPENDE_DA`, `OSPITA`, `SCAMBIA_DATI_CON`, `PROTEGGE`, `AUTENTICA`, `ALTRO` | Relazione tecnica tra asset. |

## `organization`

Contiene l'anagrafica delle organizzazioni censite.

| Campo | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `organization_id` | `UUID` | PK, default `gen_random_uuid()` | Identificativo interno dell'organizzazione. |
| `legal_name` | `VARCHAR(255)` | NOT NULL | Ragione sociale. |
| `tax_code` | `VARCHAR(32)` | UNIQUE | Codice fiscale. |
| `vat_number` | `VARCHAR(32)` |  | Partita IVA. |
| `subject_type` | `subject_type` | NOT NULL | Classificazione del soggetto. |
| `acn_subject_code` | `VARCHAR(100)` |  | Codice soggetto usato per l'identificazione nel profilo. |
| `sector` | `VARCHAR(150)` |  | Settore di appartenenza. |
| `subsector` | `VARCHAR(150)` |  | Sottosettore. |
| `country` | `CHAR(2)` | NOT NULL | Paese in formato ISO a due caratteri. |
| `pec_email` | `VARCHAR(255)` | CHECK formato email | PEC dell'organizzazione. |
| `ordinary_email` | `VARCHAR(255)` |  | Email ordinaria. |
| `created_at`, `updated_at` | `TIMESTAMPTZ` | NOT NULL | Date tecniche di creazione e aggiornamento. |
| `valid_from`, `valid_to` | `TIMESTAMPTZ` | CHECK periodo valido | Intervallo di validità logica del record. |
| `is_current` | `BOOLEAN` | NOT NULL | Indica se il record rappresenta la versione corrente. |

## `business_unit`

Rappresenta unità organizzative interne.

| Campo | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `business_unit_id` | `UUID` | PK | Identificativo della business unit. |
| `organization_id` | `UUID` | FK → `organization`, NOT NULL | Organizzazione di appartenenza. |
| `name` | `VARCHAR(150)` | NOT NULL, UNIQUE per organizzazione | Nome della struttura interna. |
| `description` | `TEXT` |  | Descrizione funzionale. |
| `created_at`, `updated_at` | `TIMESTAMPTZ` | NOT NULL | Date tecniche. |

## `contact_person`

Contiene i referenti interni o esterni associati all'organizzazione.

| Campo | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `contact_id` | `UUID` | PK | Identificativo del contatto. |
| `organization_id` | `UUID` | FK → `organization`, NOT NULL | Organizzazione di riferimento. |
| `full_name` | `VARCHAR(200)` | NOT NULL | Nome e cognome. |
| `job_title` | `VARCHAR(150)` |  | Ruolo aziendale. |
| `email` | `VARCHAR(255)` | NOT NULL, CHECK formato email, UNIQUE per organizzazione | Email del referente. |
| `phone` | `VARCHAR(50)` |  | Numero telefonico. |
| `is_external` | `BOOLEAN` | NOT NULL | Distingue referenti interni ed esterni. |
| `created_at`, `updated_at` | `TIMESTAMPTZ` | NOT NULL | Date tecniche. |

## `supplier`

Anagrafica dei fornitori terzi.

| Campo | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `supplier_id` | `UUID` | PK | Identificativo del fornitore. |
| `legal_name` | `VARCHAR(255)` | NOT NULL | Ragione sociale del fornitore. |
| `vat_number` | `VARCHAR(32)` | UNIQUE | Partita IVA o identificativo fiscale. |
| `country` | `CHAR(2)` | NOT NULL | Paese del fornitore. |
| `website` | `VARCHAR(255)` |  | Sito web. |
| `support_email` | `VARCHAR(255)` |  | Contatto supporto. |
| `security_contact_email` | `VARCHAR(255)` |  | Contatto sicurezza. |
| `notes` | `TEXT` |  | Note operative. |
| `created_at`, `updated_at` | `TIMESTAMPTZ` | NOT NULL | Date tecniche. |

## `asset`

Catalogo degli asset tecnici e informativi.

| Campo | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `asset_id` | `UUID` | PK | Identificativo dell'asset. |
| `organization_id` | `UUID` | FK → `organization`, NOT NULL | Organizzazione proprietaria. |
| `business_unit_id` | `UUID` | FK → `business_unit` | Business unit responsabile. |
| `asset_code` | `VARCHAR(80)` | NOT NULL, UNIQUE per organizzazione | Codice interno dell'asset. |
| `name` | `VARCHAR(200)` | NOT NULL | Nome descrittivo. |
| `asset_type` | `asset_type` | NOT NULL | Tipologia dell'asset. |
| `description` | `TEXT` |  | Descrizione. |
| `location` | `VARCHAR(255)` |  | Collocazione fisica o logica. |
| `environment` | `environment_type` | NOT NULL | Ambiente operativo. |
| `confidentiality`, `integrity`, `availability` | `criticality_level` | NOT NULL | Valutazione CIA. |
| `overall_criticality` | `criticality_level` | NOT NULL | Criticità complessiva. |
| `contains_personal_data` | `BOOLEAN` | NOT NULL | Presenza di dati personali. |
| `contains_sensitive_data` | `BOOLEAN` | NOT NULL | Presenza di dati sensibili. |
| `lifecycle_status` | `VARCHAR(50)` | CHECK valori ammessi | Stato dell'asset. |
| `valid_from`, `valid_to` | `TIMESTAMPTZ` | CHECK periodo valido | Validità logica. |
| `is_current` | `BOOLEAN` | NOT NULL | Versione corrente. |
| `created_at`, `updated_at` | `TIMESTAMPTZ` | NOT NULL | Date tecniche. |

## `service`

Catalogo dei servizi erogati dall'organizzazione.

| Campo | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `service_id` | `UUID` | PK | Identificativo del servizio. |
| `organization_id` | `UUID` | FK → `organization`, NOT NULL | Organizzazione che eroga il servizio. |
| `business_unit_id` | `UUID` | FK → `business_unit` | Business unit responsabile. |
| `service_code` | `VARCHAR(80)` | NOT NULL, UNIQUE per organizzazione | Codice interno del servizio. |
| `name` | `VARCHAR(200)` | NOT NULL | Nome del servizio. |
| `description` | `TEXT` |  | Descrizione funzionale. |
| `service_category` | `VARCHAR(150)` |  | Categoria del servizio. |
| `is_critical` | `BOOLEAN` | NOT NULL | Indica se il servizio è critico. |
| `criticality` | `criticality_level` | NOT NULL | Criticità del servizio. |
| `expected_service_level` | `VARCHAR(100)` |  | Livello di servizio atteso. |
| `rto_minutes`, `rpo_minutes` | `INTEGER` | CHECK >= 0 | Obiettivi di continuità operativa. |
| `valid_from`, `valid_to` | `TIMESTAMPTZ` | CHECK periodo valido | Validità logica. |
| `is_current` | `BOOLEAN` | NOT NULL | Versione corrente. |
| `created_at`, `updated_at` | `TIMESTAMPTZ` | NOT NULL | Date tecniche. |

## `service_asset`

Tabella ponte tra servizi e asset.

| Campo | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `service_id` | `UUID` | PK, FK → `service` | Servizio coinvolto. |
| `asset_id` | `UUID` | PK, FK → `asset` | Asset utilizzato dal servizio. |
| `role_description` | `VARCHAR(200)` |  | Ruolo dell'asset nel servizio. |
| `is_mandatory` | `BOOLEAN` | NOT NULL | Indica se l'asset è necessario all'erogazione. |
| `created_at` | `TIMESTAMPTZ` | NOT NULL | Data di inserimento. |

## `asset_relation`

Rappresenta relazioni tecniche tra asset.

| Campo | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `asset_relation_id` | `UUID` | PK | Identificativo della relazione. |
| `source_asset_id` | `UUID` | FK → `asset`, NOT NULL | Asset sorgente. |
| `target_asset_id` | `UUID` | FK → `asset`, NOT NULL | Asset destinazione. |
| `relation_type` | `relation_type` | NOT NULL | Tipo di relazione. |
| `description` | `TEXT` |  | Descrizione della dipendenza. |
| `created_at` | `TIMESTAMPTZ` | NOT NULL | Data di creazione. |

## `responsibility_assignment`

Associazione tra referente e responsabilità su asset o servizio.

| Campo | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `responsibility_id` | `UUID` | PK | Identificativo dell'assegnazione. |
| `organization_id` | `UUID` | FK → `organization`, NOT NULL | Organizzazione. |
| `contact_id` | `UUID` | FK → `contact_person`, NOT NULL | Referente assegnato. |
| `role` | `responsibility_role` | NOT NULL | Tipo di responsabilità. |
| `asset_id` | `UUID` | FK → `asset`, alternativa a `service_id` | Asset oggetto della responsabilità. |
| `service_id` | `UUID` | FK → `service`, alternativa a `asset_id` | Servizio oggetto della responsabilità. |
| `notes` | `TEXT` |  | Note operative. |
| `valid_from`, `valid_to` | `TIMESTAMPTZ` | CHECK periodo valido | Validità dell'assegnazione. |
| `is_current` | `BOOLEAN` | NOT NULL | Versione corrente. |
| `created_at`, `updated_at` | `TIMESTAMPTZ` | NOT NULL | Date tecniche. |

## `supplier_dependency`

Registra le dipendenze da fornitori terzi.

| Campo | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `dependency_id` | `UUID` | PK | Identificativo della dipendenza. |
| `organization_id` | `UUID` | FK → `organization`, NOT NULL | Organizzazione che dipende dal fornitore. |
| `supplier_id` | `UUID` | FK → `supplier`, NOT NULL | Fornitore coinvolto. |
| `dependency_type` | `dependency_type` | NOT NULL | Natura della dipendenza. |
| `asset_id` | `UUID` | FK → `asset`, opzionale | Asset coinvolto. |
| `service_id` | `UUID` | FK → `service`, opzionale | Servizio coinvolto. |
| `contract_reference` | `VARCHAR(120)` |  | Riferimento contrattuale. |
| `sla_description` | `VARCHAR(255)` |  | Sintesi SLA. |
| `is_critical` | `BOOLEAN` | NOT NULL | Indica se la dipendenza è critica. |
| `exit_strategy` | `TEXT` |  | Strategia di uscita o mitigazione. |
| `valid_from`, `valid_to` | `TIMESTAMPTZ` | CHECK periodo valido | Validità della dipendenza. |
| `is_current` | `BOOLEAN` | NOT NULL | Versione corrente. |
| `created_at`, `updated_at` | `TIMESTAMPTZ` | NOT NULL | Date tecniche. |

## `audit_log`

Tabella tecnica per la registrazione dello storico delle modifiche.

| Campo | Tipo | Vincoli | Descrizione |
|---|---|---|---|
| `audit_id` | `BIGSERIAL` | PK | Identificativo progressivo dell'evento. |
| `table_name` | `TEXT` | NOT NULL | Tabella modificata. |
| `record_id` | `TEXT` | NOT NULL | Identificativo del record modificato. |
| `operation` | `CHAR(1)` | CHECK `I`, `U`, `D` | Operazione eseguita. |
| `changed_at` | `TIMESTAMPTZ` | NOT NULL | Timestamp della modifica. |
| `changed_by` | `TEXT` | NOT NULL | Utente database che ha effettuato la modifica. |
| `old_data` | `JSONB` |  | Stato precedente del record. |
| `new_data` | `JSONB` |  | Stato successivo del record. |
