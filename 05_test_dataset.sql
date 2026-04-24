-- Project Work NIS2 / ACN - Punto 2
-- Query e view per generare output strutturati CSV utili alla compilazione
-- di porzioni del profilo ACN: asset critici, servizi, dipendenze e contatti.
-- RDBMS: PostgreSQL 15+

SET search_path TO nis2_registry;

-- =============================================================
-- 1. Query: elenco asset critici per azienda
-- =============================================================
-- Estrae gli asset correnti classificati con criticità ALTA o CRITICA.
-- I campi sono pensati per descrivere l'asset, il contesto organizzativo,
-- la classificazione di criticità e l'eventuale trattamento di dati personali.

SELECT
    o.legal_name AS azienda,
    o.acn_subject_code AS codice_soggetto_acn,
    bu.name AS business_unit,
    a.asset_code AS codice_asset,
    a.name AS nome_asset,
    a.asset_type AS tipo_asset,
    a.environment AS ambiente,
    a.location AS ubicazione,
    a.overall_criticality AS criticita_complessiva,
    a.confidentiality AS riservatezza,
    a.integrity AS integrita,
    a.availability AS disponibilita,
    a.contains_personal_data AS contiene_dati_personali,
    a.contains_sensitive_data AS contiene_dati_sensibili,
    a.lifecycle_status AS stato_ciclo_vita
FROM organization o
JOIN asset a ON a.organization_id = o.organization_id
LEFT JOIN business_unit bu ON bu.business_unit_id = a.business_unit_id
WHERE a.is_current = TRUE
  AND a.overall_criticality IN ('ALTA', 'CRITICA')
ORDER BY o.legal_name, a.overall_criticality DESC, a.asset_code;

-- =============================================================
-- 2. Query: elenco servizi erogati per azienda
-- =============================================================
-- Estrae i servizi correnti, evidenziando quelli critici e i principali
-- parametri di continuità operativa: RTO, RPO e livello di servizio atteso.

SELECT
    o.legal_name AS azienda,
    o.acn_subject_code AS codice_soggetto_acn,
    bu.name AS business_unit,
    s.service_code AS codice_servizio,
    s.name AS nome_servizio,
    s.service_category AS categoria_servizio,
    s.is_critical AS servizio_critico,
    s.criticality AS criticita_servizio,
    s.expected_service_level AS livello_servizio_atteso,
    s.rto_minutes AS rto_minuti,
    s.rpo_minutes AS rpo_minuti,
    STRING_AGG(DISTINCT a.asset_code || ' - ' || a.name, '; ' ORDER BY a.asset_code || ' - ' || a.name) AS asset_collegati
FROM organization o
JOIN service s ON s.organization_id = o.organization_id
LEFT JOIN business_unit bu ON bu.business_unit_id = s.business_unit_id
LEFT JOIN service_asset sa ON sa.service_id = s.service_id
LEFT JOIN asset a ON a.asset_id = sa.asset_id
WHERE s.is_current = TRUE
GROUP BY
    o.legal_name, o.acn_subject_code, bu.name, s.service_code, s.name,
    s.service_category, s.is_critical, s.criticality,
    s.expected_service_level, s.rto_minutes, s.rpo_minutes
ORDER BY o.legal_name, s.is_critical DESC, s.service_code;

-- =============================================================
-- 3. Query: dipendenze da fornitori terzi
-- =============================================================
-- Estrae le dipendenze esterne attive, distinguendo se la dipendenza riguarda
-- un servizio, un asset oppure entrambi. Include contatti di supporto e sicurezza
-- del fornitore, informazioni contrattuali, SLA e strategia di uscita.

SELECT
    o.legal_name AS azienda,
    o.acn_subject_code AS codice_soggetto_acn,
    sp.legal_name AS fornitore,
    sp.vat_number AS partita_iva_fornitore,
    sp.country AS paese_fornitore,
    sp.support_email AS email_supporto_fornitore,
    sp.security_contact_email AS email_sicurezza_fornitore,
    sd.dependency_type AS tipo_dipendenza,
    COALESCE(s.service_code, '-') AS codice_servizio,
    COALESCE(s.name, '-') AS nome_servizio,
    COALESCE(a.asset_code, '-') AS codice_asset,
    COALESCE(a.name, '-') AS nome_asset,
    sd.contract_reference AS riferimento_contratto,
    sd.sla_description AS descrizione_sla,
    sd.is_critical AS dipendenza_critica,
    sd.exit_strategy AS strategia_uscita
FROM supplier_dependency sd
JOIN organization o ON o.organization_id = sd.organization_id
JOIN supplier sp ON sp.supplier_id = sd.supplier_id
LEFT JOIN service s ON s.service_id = sd.service_id
LEFT JOIN asset a ON a.asset_id = sd.asset_id
WHERE sd.is_current = TRUE
ORDER BY o.legal_name, sd.is_critical DESC, sp.legal_name;

-- =============================================================
-- 4. Query: punti di contatto e responsabilità
-- =============================================================
-- Estrae i referenti organizzativi associati ad asset o servizi, con il ruolo
-- assegnato e l'oggetto della responsabilità.

SELECT
    o.legal_name AS azienda,
    o.acn_subject_code AS codice_soggetto_acn,
    c.full_name AS nominativo,
    c.job_title AS ruolo_aziendale,
    c.email AS email,
    c.phone AS telefono,
    c.is_external AS referente_esterno,
    ra.role AS responsabilita,
    CASE
        WHEN ra.asset_id IS NOT NULL THEN 'ASSET'
        WHEN ra.service_id IS NOT NULL THEN 'SERVIZIO'
    END AS ambito_responsabilita,
    COALESCE(a.asset_code, s.service_code) AS codice_oggetto,
    COALESCE(a.name, s.name) AS nome_oggetto,
    ra.notes AS note
FROM responsibility_assignment ra
JOIN organization o ON o.organization_id = ra.organization_id
JOIN contact_person c ON c.contact_id = ra.contact_id
LEFT JOIN asset a ON a.asset_id = ra.asset_id
LEFT JOIN service s ON s.service_id = ra.service_id
WHERE ra.is_current = TRUE
ORDER BY o.legal_name, ra.role, c.full_name;

-- =============================================================
-- 5. View unica per esportazione CSV del profilo ACN
-- =============================================================
-- La view normalizza in un unico tracciato record le informazioni minime utili
-- all'inclusione nel profilo: asset, servizio, fornitore e punto di contatto.
-- Un servizio può generare più righe se collegato a più asset, fornitori o referenti:
-- questa scelta mantiene la tracciabilità delle relazioni senza perdere dettaglio.

CREATE OR REPLACE VIEW v_acn_profile_csv AS
SELECT
    o.legal_name AS azienda,
    o.tax_code AS codice_fiscale,
    o.vat_number AS partita_iva,
    o.subject_type AS classificazione_soggetto,
    o.acn_subject_code AS codice_soggetto_acn,
    o.sector AS settore,
    o.subsector AS sottosettore,
    bu.name AS business_unit,

    s.service_code AS codice_servizio,
    s.name AS nome_servizio,
    s.service_category AS categoria_servizio,
    s.is_critical AS servizio_critico,
    s.criticality AS criticita_servizio,
    s.expected_service_level AS livello_servizio_atteso,
    s.rto_minutes AS rto_minuti,
    s.rpo_minutes AS rpo_minuti,

    a.asset_code AS codice_asset,
    a.name AS nome_asset,
    a.asset_type AS tipo_asset,
    a.environment AS ambiente_asset,
    a.location AS ubicazione_asset,
    a.overall_criticality AS criticita_asset,
    a.contains_personal_data AS contiene_dati_personali,
    a.contains_sensitive_data AS contiene_dati_sensibili,

    sp.legal_name AS fornitore,
    sp.vat_number AS partita_iva_fornitore,
    sp.country AS paese_fornitore,
    sd.dependency_type AS tipo_dipendenza,
    sd.contract_reference AS riferimento_contratto,
    sd.sla_description AS descrizione_sla,
    sd.is_critical AS dipendenza_critica,
    sd.exit_strategy AS strategia_uscita,

    c.full_name AS punto_contatto,
    c.job_title AS ruolo_aziendale_contatto,
    c.email AS email_contatto,
    c.phone AS telefono_contatto,
    ra.role AS responsabilita,

    now()::date AS data_estrazione
FROM organization o
LEFT JOIN service s
    ON s.organization_id = o.organization_id
   AND s.is_current = TRUE
LEFT JOIN business_unit bu
    ON bu.business_unit_id = s.business_unit_id
LEFT JOIN service_asset sa
    ON sa.service_id = s.service_id
LEFT JOIN asset a
    ON a.asset_id = sa.asset_id
   AND a.is_current = TRUE
LEFT JOIN supplier_dependency sd
    ON sd.organization_id = o.organization_id
   AND sd.is_current = TRUE
   AND (
        sd.service_id = s.service_id
        OR sd.asset_id = a.asset_id
   )
LEFT JOIN supplier sp
    ON sp.supplier_id = sd.supplier_id
LEFT JOIN responsibility_assignment ra
    ON ra.organization_id = o.organization_id
   AND ra.is_current = TRUE
   AND (
        ra.service_id = s.service_id
        OR ra.asset_id = a.asset_id
   )
LEFT JOIN contact_person c
    ON c.contact_id = ra.contact_id
WHERE o.is_current = TRUE;

-- =============================================================
-- 6. Funzione parametrica per esportare il profilo di una singola azienda
-- =============================================================
-- La funzione consente di filtrare l'output per codice fiscale o partita IVA.
-- È utile quando il database contiene più organizzazioni.

CREATE OR REPLACE FUNCTION fn_acn_profile_csv(p_company_identifier TEXT)
RETURNS TABLE (
    azienda VARCHAR,
    codice_fiscale VARCHAR,
    partita_iva VARCHAR,
    classificazione_soggetto subject_type,
    codice_soggetto_acn VARCHAR,
    settore VARCHAR,
    sottosettore VARCHAR,
    business_unit VARCHAR,
    codice_servizio VARCHAR,
    nome_servizio VARCHAR,
    categoria_servizio VARCHAR,
    servizio_critico BOOLEAN,
    criticita_servizio criticality_level,
    livello_servizio_atteso VARCHAR,
    rto_minuti INTEGER,
    rpo_minuti INTEGER,
    codice_asset VARCHAR,
    nome_asset VARCHAR,
    tipo_asset asset_type,
    ambiente_asset environment_type,
    ubicazione_asset VARCHAR,
    criticita_asset criticality_level,
    contiene_dati_personali BOOLEAN,
    contiene_dati_sensibili BOOLEAN,
    fornitore VARCHAR,
    partita_iva_fornitore VARCHAR,
    paese_fornitore CHAR,
    tipo_dipendenza dependency_type,
    riferimento_contratto VARCHAR,
    descrizione_sla VARCHAR,
    dipendenza_critica BOOLEAN,
    strategia_uscita TEXT,
    punto_contatto VARCHAR,
    ruolo_aziendale_contatto VARCHAR,
    email_contatto VARCHAR,
    telefono_contatto VARCHAR,
    responsabilita responsibility_role,
    data_estrazione DATE
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        v.azienda,
        v.codice_fiscale,
        v.partita_iva,
        v.classificazione_soggetto,
        v.codice_soggetto_acn,
        v.settore,
        v.sottosettore,
        v.business_unit,
        v.codice_servizio,
        v.nome_servizio,
        v.categoria_servizio,
        v.servizio_critico,
        v.criticita_servizio,
        v.livello_servizio_atteso,
        v.rto_minuti,
        v.rpo_minuti,
        v.codice_asset,
        v.nome_asset,
        v.tipo_asset,
        v.ambiente_asset,
        v.ubicazione_asset,
        v.criticita_asset,
        v.contiene_dati_personali,
        v.contiene_dati_sensibili,
        v.fornitore,
        v.partita_iva_fornitore,
        v.paese_fornitore,
        v.tipo_dipendenza,
        v.riferimento_contratto,
        v.descrizione_sla,
        v.dipendenza_critica,
        v.strategia_uscita,
        v.punto_contatto,
        v.ruolo_aziendale_contatto,
        v.email_contatto,
        v.telefono_contatto,
        v.responsabilita,
        v.data_estrazione
    FROM v_acn_profile_csv v
    WHERE v.codice_fiscale = p_company_identifier
       OR v.partita_iva = p_company_identifier
       OR v.codice_soggetto_acn = p_company_identifier
    ORDER BY v.codice_servizio, v.codice_asset, v.fornitore, v.punto_contatto;
$$;

-- =============================================================
-- 7. Comandi di esportazione CSV
-- =============================================================
-- Da psql si può esportare l'intero tracciato con:
-- \copy (SELECT * FROM nis2_registry.v_acn_profile_csv ORDER BY azienda, codice_servizio, codice_asset) TO 'export/acn_profile_all.csv' WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');
--
-- Oppure il profilo di una singola azienda:
-- \copy (SELECT * FROM nis2_registry.fn_acn_profile_csv('12345678901')) TO 'export/acn_profile_azienda_digitale.csv' WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');
