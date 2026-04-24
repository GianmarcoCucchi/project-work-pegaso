-- Project Work NIS2 / ACN - Punto 4
-- Script di test senza dipendenze esterne.
-- Eseguire dopo 01_schema.sql, 02_seed.sql, 04_acn_csv_export.sql e 05_test_dataset.sql.

SET search_path TO nis2_registry;

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM organization;
    IF v_count < 2 THEN
        RAISE EXCEPTION 'Test fallito: organizzazioni attese >= 2, trovate %', v_count;
    END IF;

    SELECT COUNT(*) INTO v_count FROM asset WHERE overall_criticality IN ('ALTA', 'CRITICA') AND is_current = TRUE;
    IF v_count < 4 THEN
        RAISE EXCEPTION 'Test fallito: asset critici attesi >= 4, trovati %', v_count;
    END IF;

    SELECT COUNT(*) INTO v_count FROM service WHERE is_critical = TRUE AND is_current = TRUE;
    IF v_count < 3 THEN
        RAISE EXCEPTION 'Test fallito: servizi critici attesi >= 3, trovati %', v_count;
    END IF;

    SELECT COUNT(*) INTO v_count FROM supplier_dependency WHERE is_critical = TRUE AND is_current = TRUE;
    IF v_count < 4 THEN
        RAISE EXCEPTION 'Test fallito: dipendenze critiche attese >= 4, trovate %', v_count;
    END IF;

    SELECT COUNT(*) INTO v_count FROM responsibility_assignment WHERE is_current = TRUE;
    IF v_count < 4 THEN
        RAISE EXCEPTION 'Test fallito: responsabilità attese >= 4, trovate %', v_count;
    END IF;

    SELECT COUNT(*) INTO v_count FROM v_acn_profile_csv;
    IF v_count = 0 THEN
        RAISE EXCEPTION 'Test fallito: la view v_acn_profile_csv non produce righe';
    END IF;

    SELECT COUNT(*) INTO v_count FROM fn_acn_profile_csv('12345678901');
    IF v_count = 0 THEN
        RAISE EXCEPTION 'Test fallito: la funzione non produce righe per Azienda Digitale S.p.A.';
    END IF;

    SELECT COUNT(*) INTO v_count FROM fn_acn_profile_csv('09876543210');
    IF v_count = 0 THEN
        RAISE EXCEPTION 'Test fallito: la funzione non produce righe per Sanitaria Nord S.r.l.';
    END IF;

    RAISE NOTICE 'Tutti i test logici sono stati superati correttamente.';
END $$;

SELECT 'organizzazioni' AS controllo, COUNT(*) AS valore FROM organization
UNION ALL
SELECT 'business unit', COUNT(*) FROM business_unit
UNION ALL
SELECT 'contatti', COUNT(*) FROM contact_person
UNION ALL
SELECT 'fornitori', COUNT(*) FROM supplier
UNION ALL
SELECT 'asset', COUNT(*) FROM asset
UNION ALL
SELECT 'servizi', COUNT(*) FROM service
UNION ALL
SELECT 'dipendenze fornitori', COUNT(*) FROM supplier_dependency
UNION ALL
SELECT 'responsabilità', COUNT(*) FROM responsibility_assignment
UNION ALL
SELECT 'righe view CSV', COUNT(*) FROM v_acn_profile_csv
ORDER BY controllo;
