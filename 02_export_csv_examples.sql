-- Project Work NIS2 / ACN - Punto 4
-- Dataset simulato aggiuntivo per verificare query ed esportazione CSV.
-- I dati sono fittizi e non riferiti a organizzazioni reali.

SET search_path TO nis2_registry;

INSERT INTO organization (legal_name, tax_code, vat_number, subject_type, acn_subject_code, sector, subsector, pec_email, ordinary_email)
VALUES
('Sanitaria Nord S.r.l.', '09876543210', 'IT09876543210', 'ESSENZIALE', 'ACN-DEMO-002', 'Sanità', 'Servizi sanitari digitali', 'sanitaria.nord@pec.example', 'ict@sanitarianord.example');

INSERT INTO business_unit (organization_id, name, description)
SELECT organization_id, 'Sistemi Clinici', 'Unità responsabile delle piattaforme cliniche e dei servizi digitali sanitari'
FROM organization
WHERE tax_code = '09876543210';

INSERT INTO contact_person (organization_id, full_name, job_title, email, phone)
SELECT organization_id, 'Laura Verdi', 'Responsabile Sistemi Informativi', 'laura.verdi@sanitarianord.example', '+390201112233'
FROM organization
WHERE tax_code = '09876543210';

INSERT INTO contact_person (organization_id, full_name, job_title, email, phone)
SELECT organization_id, 'Paolo Neri', 'Referente Sicurezza ICT', 'paolo.neri@sanitarianord.example', '+390204445566'
FROM organization
WHERE tax_code = '09876543210';

INSERT INTO supplier (legal_name, vat_number, country, website, support_email, security_contact_email, notes)
VALUES
('Managed Security Demo S.r.l.', 'IT55566677788', 'IT', 'https://mss-demo.example', 'support@mss-demo.example', 'soc@mss-demo.example', 'Fornitore fittizio per servizi SOC e monitoraggio'),
('Software Clinico Demo S.p.A.', 'IT22233344455', 'IT', 'https://clinical-demo.example', 'assistenza@clinical-demo.example', 'security@clinical-demo.example', 'Fornitore fittizio della piattaforma clinica');

INSERT INTO asset (organization_id, business_unit_id, asset_code, name, asset_type, description, location, environment, confidentiality, integrity, availability, overall_criticality, contains_personal_data, contains_sensitive_data)
SELECT o.organization_id, bu.business_unit_id, 'AST-CLIN-001', 'Piattaforma cartella clinica', 'APPLICAZIONE', 'Applicazione per gestione documentazione sanitaria e percorsi assistenziali', 'Cloud EU', 'PRODUZIONE', 'CRITICA', 'CRITICA', 'ALTA', 'CRITICA', TRUE, TRUE
FROM organization o
JOIN business_unit bu ON bu.organization_id = o.organization_id
WHERE o.tax_code = '09876543210' AND bu.name = 'Sistemi Clinici';

INSERT INTO asset (organization_id, business_unit_id, asset_code, name, asset_type, description, location, environment, confidentiality, integrity, availability, overall_criticality, contains_personal_data, contains_sensitive_data)
SELECT o.organization_id, bu.business_unit_id, 'AST-SOC-001', 'Sistema monitoraggio eventi sicurezza', 'APPLICAZIONE', 'Piattaforma SIEM/SOC per raccolta e correlazione log di sicurezza', 'SOC esterno - EU', 'PRODUZIONE', 'ALTA', 'ALTA', 'ALTA', 'ALTA', FALSE, FALSE
FROM organization o
JOIN business_unit bu ON bu.organization_id = o.organization_id
WHERE o.tax_code = '09876543210' AND bu.name = 'Sistemi Clinici';

INSERT INTO service (organization_id, business_unit_id, service_code, name, description, service_category, is_critical, criticality, expected_service_level, rto_minutes, rpo_minutes)
SELECT o.organization_id, bu.business_unit_id, 'SRV-CLIN-001', 'Servizio cartella clinica digitale', 'Servizio applicativo per consultazione e aggiornamento della cartella clinica', 'Servizi sanitari digitali', TRUE, 'CRITICA', 'Disponibilità mensile 99,7%', 120, 30
FROM organization o
JOIN business_unit bu ON bu.organization_id = o.organization_id
WHERE o.tax_code = '09876543210' AND bu.name = 'Sistemi Clinici';

INSERT INTO service (organization_id, business_unit_id, service_code, name, description, service_category, is_critical, criticality, expected_service_level, rto_minutes, rpo_minutes)
SELECT o.organization_id, bu.business_unit_id, 'SRV-SOC-001', 'Servizio monitoraggio sicurezza', 'Servizio di monitoraggio, alerting e gestione eventi di sicurezza', 'Sicurezza ICT', TRUE, 'ALTA', 'Presidio SOC h24', 60, 15
FROM organization o
JOIN business_unit bu ON bu.organization_id = o.organization_id
WHERE o.tax_code = '09876543210' AND bu.name = 'Sistemi Clinici';

INSERT INTO service_asset (service_id, asset_id, role_description, is_mandatory)
SELECT s.service_id, a.asset_id, 'Asset applicativo principale del servizio', TRUE
FROM service s
JOIN asset a ON a.organization_id = s.organization_id
WHERE s.service_code = 'SRV-CLIN-001' AND a.asset_code = 'AST-CLIN-001';

INSERT INTO service_asset (service_id, asset_id, role_description, is_mandatory)
SELECT s.service_id, a.asset_id, 'Asset usato per monitoraggio e rilevamento eventi', TRUE
FROM service s
JOIN asset a ON a.organization_id = s.organization_id
WHERE s.service_code = 'SRV-SOC-001' AND a.asset_code = 'AST-SOC-001';

INSERT INTO responsibility_assignment (organization_id, contact_id, role, service_id, notes)
SELECT o.organization_id, c.contact_id, 'OWNER', s.service_id, 'Owner del servizio per censimento e aggiornamento dati'
FROM organization o
JOIN contact_person c ON c.organization_id = o.organization_id
JOIN service s ON s.organization_id = o.organization_id
WHERE o.tax_code = '09876543210' AND c.email = 'laura.verdi@sanitarianord.example' AND s.service_code = 'SRV-CLIN-001';

INSERT INTO responsibility_assignment (organization_id, contact_id, role, asset_id, notes)
SELECT o.organization_id, c.contact_id, 'RESPONSABILE_SICUREZZA', a.asset_id, 'Referente sicurezza per asset e log di monitoraggio'
FROM organization o
JOIN contact_person c ON c.organization_id = o.organization_id
JOIN asset a ON a.organization_id = o.organization_id
WHERE o.tax_code = '09876543210' AND c.email = 'paolo.neri@sanitarianord.example' AND a.asset_code = 'AST-SOC-001';

INSERT INTO supplier_dependency (organization_id, supplier_id, dependency_type, service_id, contract_reference, sla_description, is_critical, exit_strategy)
SELECT o.organization_id, sp.supplier_id, 'SOFTWARE', s.service_id, 'CTR-CLIN-2026-001', 'Manutenzione applicativa con presa in carico entro 4 ore', TRUE, 'Esportazione dati in formato standard e migrazione verso soluzione alternativa entro 120 giorni'
FROM organization o
JOIN supplier sp ON sp.vat_number = 'IT22233344455'
JOIN service s ON s.organization_id = o.organization_id
WHERE o.tax_code = '09876543210' AND s.service_code = 'SRV-CLIN-001';

INSERT INTO supplier_dependency (organization_id, supplier_id, dependency_type, service_id, contract_reference, sla_description, is_critical, exit_strategy)
SELECT o.organization_id, sp.supplier_id, 'SUPPORTO', s.service_id, 'CTR-SOC-2026-002', 'Servizio SOC h24 con notifica eventi critici entro 30 minuti', TRUE, 'Piano di subentro con esportazione regole, log e procedure operative'
FROM organization o
JOIN supplier sp ON sp.vat_number = 'IT55566677788'
JOIN service s ON s.organization_id = o.organization_id
WHERE o.tax_code = '09876543210' AND s.service_code = 'SRV-SOC-001';

INSERT INTO asset_relation (source_asset_id, target_asset_id, relation_type, description)
SELECT a1.asset_id, a2.asset_id, 'SCAMBIA_DATI_CON', 'Invio log applicativi e di sicurezza verso piattaforma SOC'
FROM asset a1
JOIN asset a2 ON a2.organization_id = a1.organization_id
JOIN organization o ON o.organization_id = a1.organization_id
WHERE o.tax_code = '09876543210'
  AND a1.asset_code = 'AST-CLIN-001'
  AND a2.asset_code = 'AST-SOC-001';
