-- Query rapide di verifica per il Punto 1
SET search_path TO nis2_registry;

-- Conteggio record principali
SELECT 'organization' AS tabella, count(*) AS record FROM organization
UNION ALL SELECT 'asset', count(*) FROM asset
UNION ALL SELECT 'service', count(*) FROM service
UNION ALL SELECT 'supplier_dependency', count(*) FROM supplier_dependency
UNION ALL SELECT 'responsibility_assignment', count(*) FROM responsibility_assignment;

-- Asset critici correnti
SELECT asset_code, name, asset_type, overall_criticality, contains_personal_data
FROM asset
WHERE is_current = TRUE AND overall_criticality IN ('ALTA', 'CRITICA')
ORDER BY overall_criticality DESC, asset_code;

-- Verifica audit log
SELECT table_name, operation, count(*) AS eventi
FROM audit_log
GROUP BY table_name, operation
ORDER BY table_name, operation;
