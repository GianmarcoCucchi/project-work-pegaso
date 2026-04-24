-- Project Work NIS2 / ACN - Punto 1
-- Schema relazionale PostgreSQL per catalogare organizzazioni, asset, servizi,
-- dipendenze da terze parti, responsabilità e storico modifiche.
-- RDBMS consigliato: PostgreSQL 15+

CREATE SCHEMA IF NOT EXISTS nis2_registry;
SET search_path TO nis2_registry;

-- Estensione utile per UUID automatici
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================
-- Tipi enumerativi di dominio
-- =========================

CREATE TYPE subject_type AS ENUM ('ESSENZIALE', 'IMPORTANTE', 'NON_CLASSIFICATO');
CREATE TYPE asset_type AS ENUM ('SERVER', 'DATABASE', 'APPLICAZIONE', 'RETE', 'CLOUD', 'ENDPOINT', 'DISPOSITIVO_OT_IOT', 'ALTRO');
CREATE TYPE criticality_level AS ENUM ('BASSA', 'MEDIA', 'ALTA', 'CRITICA');
CREATE TYPE environment_type AS ENUM ('PRODUZIONE', 'TEST', 'SVILUPPO', 'DR', 'ALTRO');
CREATE TYPE responsibility_role AS ENUM ('OWNER', 'RESPONSABILE_TECNICO', 'RESPONSABILE_SICUREZZA', 'REFERENTE_BUSINESS', 'REFERENTE_FORNITORE', 'DPO', 'ALTRO');
CREATE TYPE dependency_type AS ENUM ('HOSTING', 'CONNETTIVITA', 'SOFTWARE', 'MANUTENZIONE', 'SUPPORTO', 'CLOUD', 'DATI', 'ALTRO');
CREATE TYPE relation_type AS ENUM ('DIPENDE_DA', 'OSPITA', 'SCAMBIA_DATI_CON', 'PROTEGGE', 'AUTENTICA', 'ALTRO');

-- =========================
-- Tabelle anagrafiche
-- =========================

CREATE TABLE organization (
    organization_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legal_name VARCHAR(255) NOT NULL,
    tax_code VARCHAR(32),
    vat_number VARCHAR(32),
    subject_type subject_type NOT NULL DEFAULT 'NON_CLASSIFICATO',
    acn_subject_code VARCHAR(100),
    sector VARCHAR(150),
    subsector VARCHAR(150),
    country CHAR(2) NOT NULL DEFAULT 'IT',
    pec_email VARCHAR(255),
    ordinary_email VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to TIMESTAMPTZ,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_organization_tax_code UNIQUE (tax_code),
    CONSTRAINT ck_organization_validity CHECK (valid_to IS NULL OR valid_to > valid_from),
    CONSTRAINT ck_organization_email CHECK (
        pec_email IS NULL OR pec_email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
    )
);

CREATE TABLE business_unit (
    business_unit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organization(organization_id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_business_unit_org_name UNIQUE (organization_id, name)
);

CREATE TABLE contact_person (
    contact_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organization(organization_id) ON DELETE CASCADE,
    full_name VARCHAR(200) NOT NULL,
    job_title VARCHAR(150),
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    is_external BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_contact_org_email UNIQUE (organization_id, email),
    CONSTRAINT ck_contact_email CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$')
);

CREATE TABLE supplier (
    supplier_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legal_name VARCHAR(255) NOT NULL,
    vat_number VARCHAR(32),
    country CHAR(2) NOT NULL DEFAULT 'IT',
    website VARCHAR(255),
    support_email VARCHAR(255),
    security_contact_email VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_supplier_vat UNIQUE (vat_number)
);

-- =========================
-- Asset e servizi
-- =========================

CREATE TABLE asset (
    asset_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organization(organization_id) ON DELETE CASCADE,
    business_unit_id UUID REFERENCES business_unit(business_unit_id) ON DELETE SET NULL,
    asset_code VARCHAR(80) NOT NULL,
    name VARCHAR(200) NOT NULL,
    asset_type asset_type NOT NULL,
    description TEXT,
    location VARCHAR(255),
    environment environment_type NOT NULL DEFAULT 'PRODUZIONE',
    confidentiality criticality_level NOT NULL DEFAULT 'MEDIA',
    integrity criticality_level NOT NULL DEFAULT 'MEDIA',
    availability criticality_level NOT NULL DEFAULT 'MEDIA',
    overall_criticality criticality_level NOT NULL DEFAULT 'MEDIA',
    contains_personal_data BOOLEAN NOT NULL DEFAULT FALSE,
    contains_sensitive_data BOOLEAN NOT NULL DEFAULT FALSE,
    lifecycle_status VARCHAR(50) NOT NULL DEFAULT 'ATTIVO',
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to TIMESTAMPTZ,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_asset_org_code UNIQUE (organization_id, asset_code),
    CONSTRAINT ck_asset_validity CHECK (valid_to IS NULL OR valid_to > valid_from),
    CONSTRAINT ck_asset_status CHECK (lifecycle_status IN ('ATTIVO', 'DISMESSO', 'IN_MANUTENZIONE', 'PIANIFICATO'))
);

CREATE TABLE service (
    service_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organization(organization_id) ON DELETE CASCADE,
    business_unit_id UUID REFERENCES business_unit(business_unit_id) ON DELETE SET NULL,
    service_code VARCHAR(80) NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    service_category VARCHAR(150),
    is_critical BOOLEAN NOT NULL DEFAULT FALSE,
    criticality criticality_level NOT NULL DEFAULT 'MEDIA',
    expected_service_level VARCHAR(100),
    rto_minutes INTEGER,
    rpo_minutes INTEGER,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to TIMESTAMPTZ,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_service_org_code UNIQUE (organization_id, service_code),
    CONSTRAINT ck_service_validity CHECK (valid_to IS NULL OR valid_to > valid_from),
    CONSTRAINT ck_service_rto CHECK (rto_minutes IS NULL OR rto_minutes >= 0),
    CONSTRAINT ck_service_rpo CHECK (rpo_minutes IS NULL OR rpo_minutes >= 0)
);

CREATE TABLE service_asset (
    service_id UUID NOT NULL REFERENCES service(service_id) ON DELETE CASCADE,
    asset_id UUID NOT NULL REFERENCES asset(asset_id) ON DELETE RESTRICT,
    role_description VARCHAR(200),
    is_mandatory BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (service_id, asset_id)
);

CREATE TABLE asset_relation (
    asset_relation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_asset_id UUID NOT NULL REFERENCES asset(asset_id) ON DELETE CASCADE,
    target_asset_id UUID NOT NULL REFERENCES asset(asset_id) ON DELETE CASCADE,
    relation_type relation_type NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_asset_relation_not_self CHECK (source_asset_id <> target_asset_id),
    CONSTRAINT uq_asset_relation UNIQUE (source_asset_id, target_asset_id, relation_type)
);

-- =========================
-- Responsabilità
-- =========================

CREATE TABLE responsibility_assignment (
    responsibility_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organization(organization_id) ON DELETE CASCADE,
    contact_id UUID NOT NULL REFERENCES contact_person(contact_id) ON DELETE RESTRICT,
    role responsibility_role NOT NULL,
    asset_id UUID REFERENCES asset(asset_id) ON DELETE CASCADE,
    service_id UUID REFERENCES service(service_id) ON DELETE CASCADE,
    notes TEXT,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to TIMESTAMPTZ,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_responsibility_target CHECK (
        (asset_id IS NOT NULL AND service_id IS NULL) OR
        (asset_id IS NULL AND service_id IS NOT NULL)
    ),
    CONSTRAINT ck_responsibility_validity CHECK (valid_to IS NULL OR valid_to > valid_from)
);

-- =========================
-- Dipendenze da fornitori terzi
-- =========================

CREATE TABLE supplier_dependency (
    dependency_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organization(organization_id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES supplier(supplier_id) ON DELETE RESTRICT,
    dependency_type dependency_type NOT NULL,
    asset_id UUID REFERENCES asset(asset_id) ON DELETE CASCADE,
    service_id UUID REFERENCES service(service_id) ON DELETE CASCADE,
    contract_reference VARCHAR(120),
    sla_description VARCHAR(255),
    is_critical BOOLEAN NOT NULL DEFAULT FALSE,
    exit_strategy TEXT,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to TIMESTAMPTZ,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_dependency_target CHECK (
        asset_id IS NOT NULL OR service_id IS NOT NULL
    ),
    CONSTRAINT ck_dependency_validity CHECK (valid_to IS NULL OR valid_to > valid_from)
);

-- =========================
-- Audit e storico modifiche
-- =========================

CREATE TABLE audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id TEXT NOT NULL,
    operation CHAR(1) NOT NULL CHECK (operation IN ('I', 'U', 'D')),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    changed_by TEXT NOT NULL DEFAULT current_user,
    old_data JSONB,
    new_data JSONB
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION write_audit_log()
RETURNS TRIGGER AS $$
DECLARE
    v_data JSONB;
    v_record_id TEXT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_data := to_jsonb(OLD);
    ELSE
        v_data := to_jsonb(NEW);
    END IF;

    v_record_id := COALESCE(
        v_data ->> 'organization_id',
        v_data ->> 'business_unit_id',
        v_data ->> 'contact_id',
        v_data ->> 'supplier_id',
        v_data ->> 'asset_id',
        v_data ->> 'service_id',
        v_data ->> 'dependency_id',
        v_data ->> 'responsibility_id',
        'unknown'
    );

    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log(table_name, record_id, operation, new_data)
        VALUES (TG_TABLE_NAME, v_record_id, 'I', to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log(table_name, record_id, operation, old_data, new_data)
        VALUES (TG_TABLE_NAME, v_record_id, 'U', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log(table_name, record_id, operation, old_data)
        VALUES (TG_TABLE_NAME, v_record_id, 'D', to_jsonb(OLD));
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger updated_at
CREATE TRIGGER trg_organization_updated_at BEFORE UPDATE ON organization FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_business_unit_updated_at BEFORE UPDATE ON business_unit FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_contact_updated_at BEFORE UPDATE ON contact_person FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_supplier_updated_at BEFORE UPDATE ON supplier FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_asset_updated_at BEFORE UPDATE ON asset FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_service_updated_at BEFORE UPDATE ON service FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_responsibility_updated_at BEFORE UPDATE ON responsibility_assignment FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_dependency_updated_at BEFORE UPDATE ON supplier_dependency FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Trigger audit
CREATE TRIGGER trg_audit_organization AFTER INSERT OR UPDATE OR DELETE ON organization FOR EACH ROW EXECUTE FUNCTION write_audit_log();
CREATE TRIGGER trg_audit_asset AFTER INSERT OR UPDATE OR DELETE ON asset FOR EACH ROW EXECUTE FUNCTION write_audit_log();
CREATE TRIGGER trg_audit_service AFTER INSERT OR UPDATE OR DELETE ON service FOR EACH ROW EXECUTE FUNCTION write_audit_log();
CREATE TRIGGER trg_audit_supplier AFTER INSERT OR UPDATE OR DELETE ON supplier FOR EACH ROW EXECUTE FUNCTION write_audit_log();
CREATE TRIGGER trg_audit_contact AFTER INSERT OR UPDATE OR DELETE ON contact_person FOR EACH ROW EXECUTE FUNCTION write_audit_log();
CREATE TRIGGER trg_audit_responsibility AFTER INSERT OR UPDATE OR DELETE ON responsibility_assignment FOR EACH ROW EXECUTE FUNCTION write_audit_log();
CREATE TRIGGER trg_audit_dependency AFTER INSERT OR UPDATE OR DELETE ON supplier_dependency FOR EACH ROW EXECUTE FUNCTION write_audit_log();

-- =========================
-- Indici per performance
-- =========================

CREATE INDEX idx_asset_org_criticality ON asset(organization_id, overall_criticality) WHERE is_current = TRUE;
CREATE INDEX idx_asset_type ON asset(asset_type);
CREATE INDEX idx_service_org_critical ON service(organization_id, is_critical, criticality) WHERE is_current = TRUE;
CREATE INDEX idx_service_asset_asset ON service_asset(asset_id);
CREATE INDEX idx_dependency_org_supplier ON supplier_dependency(organization_id, supplier_id) WHERE is_current = TRUE;
CREATE INDEX idx_dependency_service ON supplier_dependency(service_id) WHERE service_id IS NOT NULL;
CREATE INDEX idx_dependency_asset ON supplier_dependency(asset_id) WHERE asset_id IS NOT NULL;
CREATE INDEX idx_responsibility_contact ON responsibility_assignment(contact_id) WHERE is_current = TRUE;
CREATE INDEX idx_audit_table_record ON audit_log(table_name, record_id, changed_at DESC);
