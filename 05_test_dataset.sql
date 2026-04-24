-- Dataset dimostrativo per testare lo schema del Punto 1
SET search_path TO nis2_registry;

INSERT INTO organization (legal_name, tax_code, vat_number, subject_type, acn_subject_code, sector, subsector, pec_email, ordinary_email)
VALUES ('Azienda Digitale S.p.A.', '12345678901', 'IT12345678901', 'IMPORTANTE', 'ACN-DEMO-001', 'Servizi digitali', 'Cloud e servizi ICT', 'azienda.digitale@pec.it', 'security@aziendadigitale.example');

INSERT INTO business_unit (organization_id, name, description)
SELECT organization_id, 'IT Operations', 'Unità responsabile delle infrastrutture e dei servizi applicativi'
FROM organization WHERE tax_code = '12345678901';

INSERT INTO contact_person (organization_id, full_name, job_title, email, phone)
SELECT organization_id, 'Mario Rossi', 'Responsabile IT', 'mario.rossi@aziendadigitale.example', '+390612345678'
FROM organization WHERE tax_code = '12345678901';

INSERT INTO contact_person (organization_id, full_name, job_title, email, phone)
SELECT organization_id, 'Giulia Bianchi', 'Security Manager', 'giulia.bianchi@aziendadigitale.example', '+390698765432'
FROM organization WHERE tax_code = '12345678901';

INSERT INTO supplier (legal_name, vat_number, country, website, support_email, security_contact_email)
VALUES
('Cloud Provider Demo S.r.l.', 'IT99988877766', 'IT', 'https://cloudprovider.example', 'support@cloudprovider.example', 'security@cloudprovider.example'),
('Connettività Demo S.p.A.', 'IT11122233344', 'IT', 'https://connectivity.example', 'assistenza@connectivity.example', 'soc@connectivity.example');

INSERT INTO asset (organization_id, business_unit_id, asset_code, name, asset_type, description, location, environment, confidentiality, integrity, availability, overall_criticality, contains_personal_data, contains_sensitive_data)
SELECT o.organization_id, bu.business_unit_id, 'AST-DB-001', 'Database clienti', 'DATABASE', 'Database principale contenente dati clienti e contratti', 'Data center cloud - EU', 'PRODUZIONE', 'ALTA', 'ALTA', 'CRITICA', 'CRITICA', TRUE, TRUE
FROM organization o JOIN business_unit bu ON bu.organization_id = o.organization_id
WHERE o.tax_code = '12345678901' AND bu.name = 'IT Operations';

INSERT INTO asset (organization_id, business_unit_id, asset_code, name, asset_type, description, location, environment, confidentiality, integrity, availability, overall_criticality, contains_personal_data, contains_sensitive_data)
SELECT o.organization_id, bu.business_unit_id, 'AST-APP-001', 'Portale clienti', 'APPLICAZIONE', 'Applicazione web usata dai clienti per accedere ai servizi digitali', 'Cloud EU', 'PRODUZIONE', 'ALTA', 'ALTA', 'CRITICA', 'CRITICA', TRUE, FALSE
FROM organization o JOIN business_unit bu ON bu.organization_id = o.organization_id
WHERE o.tax_code = '12345678901' AND bu.name = 'IT Operations';

INSERT INTO service (organization_id, business_unit_id, service_code, name, description, service_category, is_critical, criticality, expected_service_level, rto_minutes, rpo_minutes)
SELECT o.organization_id, bu.business_unit_id, 'SRV-001', 'Servizio Portale Clienti', 'Servizio digitale di accesso clienti e consultazione contratti', 'Servizi digitali B2C', TRUE, 'CRITICA', 'Disponibilità mensile 99,5%', 240, 60
FROM organization o JOIN business_unit bu ON bu.organization_id = o.organization_id
WHERE o.tax_code = '12345678901' AND bu.name = 'IT Operations';

INSERT INTO service_asset (service_id, asset_id, role_description, is_mandatory)
SELECT s.service_id, a.asset_id, 'Asset necessario al funzionamento del servizio', TRUE
FROM service s JOIN asset a ON a.organization_id = s.organization_id
WHERE s.service_code = 'SRV-001' AND a.asset_code IN ('AST-DB-001', 'AST-APP-001');

INSERT INTO responsibility_assignment (organization_id, contact_id, role, service_id, notes)
SELECT o.organization_id, c.contact_id, 'OWNER', s.service_id, 'Responsabile del servizio ai fini del profilo ACN'
FROM organization o JOIN contact_person c ON c.organization_id = o.organization_id JOIN service s ON s.organization_id = o.organization_id
WHERE o.tax_code = '12345678901' AND c.email = 'mario.rossi@aziendadigitale.example' AND s.service_code = 'SRV-001';

INSERT INTO responsibility_assignment (organization_id, contact_id, role, asset_id, notes)
SELECT o.organization_id, c.contact_id, 'RESPONSABILE_SICUREZZA', a.asset_id, 'Referente sicurezza per asset critico'
FROM organization o JOIN contact_person c ON c.organization_id = o.organization_id JOIN asset a ON a.organization_id = o.organization_id
WHERE o.tax_code = '12345678901' AND c.email = 'giulia.bianchi@aziendadigitale.example' AND a.asset_code = 'AST-DB-001';

INSERT INTO supplier_dependency (organization_id, supplier_id, dependency_type, service_id, contract_reference, sla_description, is_critical, exit_strategy)
SELECT o.organization_id, sp.supplier_id, 'CLOUD', s.service_id, 'CTR-CLOUD-2026-001', 'SLA infrastruttura 99,9%', TRUE, 'Migrazione verso secondo provider qualificato entro 90 giorni'
FROM organization o JOIN supplier sp ON sp.vat_number = 'IT99988877766' JOIN service s ON s.organization_id = o.organization_id
WHERE o.tax_code = '12345678901' AND s.service_code = 'SRV-001';

INSERT INTO supplier_dependency (organization_id, supplier_id, dependency_type, asset_id, contract_reference, sla_description, is_critical, exit_strategy)
SELECT o.organization_id, sp.supplier_id, 'CONNETTIVITA', a.asset_id, 'CTR-NET-2026-002', 'SLA connettività 99,7%', TRUE, 'Contratto alternativo con operatore secondario'
FROM organization o JOIN supplier sp ON sp.vat_number = 'IT11122233344' JOIN asset a ON a.organization_id = o.organization_id
WHERE o.tax_code = '12345678901' AND a.asset_code = 'AST-APP-001';
