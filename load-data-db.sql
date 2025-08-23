-- PostgreSQL DDL for Medical Datasets
-- Execute these statements in order to create the database schema

-- Create database (optional - run as superuser)
-- CREATE DATABASE medical_data;
-- \c medical_data;

-- Enable extensions for better data handling
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. CLINICAL TRIALS TABLE
-- =====================================================
CREATE TABLE clinical_trials (
    id SERIAL PRIMARY KEY,
    trial_id VARCHAR(100) NOT NULL UNIQUE,
    title TEXT NOT NULL,
    condition VARCHAR(500),
    intervention TEXT,
    phase VARCHAR(50),
    status VARCHAR(100),
    start_date DATE,
    end_date DATE,
    location VARCHAR(500),
    sponsor VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_clinical_trials_trial_id ON clinical_trials(trial_id);
CREATE INDEX idx_clinical_trials_condition ON clinical_trials(condition);
CREATE INDEX idx_clinical_trials_status ON clinical_trials(status);
CREATE INDEX idx_clinical_trials_phase ON clinical_trials(phase);
CREATE INDEX idx_clinical_trials_start_date ON clinical_trials(start_date);

-- =====================================================
-- 2. DRUG SAFETY TABLE
-- =====================================================
CREATE TABLE drug_safety (
    id SERIAL PRIMARY KEY,
    report_id VARCHAR(100) NOT NULL UNIQUE,
    drug_name VARCHAR(500) NOT NULL,
    adverse_event TEXT,
    serious BOOLEAN,
    outcome VARCHAR(200),
    report_date DATE,
    age INTEGER CHECK (age > 0 AND age <= 150),
    gender VARCHAR(20),
    country VARCHAR(100),
    source VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_drug_safety_report_id ON drug_safety(report_id);
CREATE INDEX idx_drug_safety_drug_name ON drug_safety(drug_name);
CREATE INDEX idx_drug_safety_serious ON drug_safety(serious);
CREATE INDEX idx_drug_safety_outcome ON drug_safety(outcome);
CREATE INDEX idx_drug_safety_report_date ON drug_safety(report_date);
CREATE INDEX idx_drug_safety_age ON drug_safety(age);
CREATE INDEX idx_drug_safety_country ON drug_safety(country);

-- =====================================================
-- 3. DRUG ONTOLOGY TABLE
-- =====================================================
CREATE TABLE drug_ontology (
    id SERIAL PRIMARY KEY,
    drug_id VARCHAR(100) NOT NULL UNIQUE,
    drug_name VARCHAR(500) NOT NULL,
    generic_name VARCHAR(500),
    drug_class VARCHAR(200),
    mechanism_of_action TEXT,
    route_of_administration VARCHAR(200),
    atc_code VARCHAR(20),
    approved BOOLEAN,
    synonyms TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_drug_ontology_drug_id ON drug_ontology(drug_id);
CREATE INDEX idx_drug_ontology_drug_name ON drug_ontology(drug_name);
CREATE INDEX idx_drug_ontology_generic_name ON drug_ontology(generic_name);
CREATE INDEX idx_drug_ontology_drug_class ON drug_ontology(drug_class);
CREATE INDEX idx_drug_ontology_atc_code ON drug_ontology(atc_code);
CREATE INDEX idx_drug_ontology_approved ON drug_ontology(approved);

-- =====================================================
-- 4. SYNTHETIC EHR TABLE
-- =====================================================
CREATE TABLE synthetic_ehr (
    id SERIAL PRIMARY KEY,
    patient_id VARCHAR(100) NOT NULL,
    age INTEGER CHECK (age > 0 AND age <= 150),
    gender VARCHAR(20),
    diagnosis VARCHAR(500),
    treatment TEXT,
    visit_date DATE,
    lab_result DECIMAL(10,4),
    outcome VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_synthetic_ehr_patient_id ON synthetic_ehr(patient_id);
CREATE INDEX idx_synthetic_ehr_age ON synthetic_ehr(age);
CREATE INDEX idx_synthetic_ehr_diagnosis ON synthetic_ehr(diagnosis);
CREATE INDEX idx_synthetic_ehr_visit_date ON synthetic_ehr(visit_date);
CREATE INDEX idx_synthetic_ehr_outcome ON synthetic_ehr(outcome);

-- =====================================================
-- DATA LOADING COMMANDS
-- =====================================================

-- Load clinical trials data
-- Note: Adjust the file path to match your local setup
COPY clinical_trials (trial_id, title, condition, intervention, phase, status, start_date, end_date, location, sponsor)
FROM '/path/to/your/clinical_trials_50k.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Load drug safety data
-- Note: Convert 'true'/'false' strings to boolean values during import
COPY drug_safety (report_id, drug_name, adverse_event, serious, outcome, report_date, age, gender, country, source)
FROM '/path/to/your/drug_safety_50k.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Load drug ontology data
COPY drug_ontology (drug_id, drug_name, generic_name, drug_class, mechanism_of_action, route_of_administration, atc_code, approved, synonyms)
FROM '/path/to/your/drug_ontology_50k.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Load synthetic EHR data
COPY synthetic_ehr (patient_id, age, gender, diagnosis, treatment, visit_date, lab_result, outcome)
FROM '/path/to/your/synthetic_ehr_50k.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- =====================================================
-- POST-LOAD DATA VALIDATION QUERIES
-- =====================================================

-- Check record counts
SELECT 'clinical_trials' as table_name, COUNT(*) as record_count FROM clinical_trials
UNION ALL
SELECT 'drug_safety' as table_name, COUNT(*) as record_count FROM drug_safety
UNION ALL
SELECT 'drug_ontology' as table_name, COUNT(*) as record_count FROM drug_ontology
UNION ALL
SELECT 'synthetic_ehr' as table_name, COUNT(*) as record_count FROM synthetic_ehr;

-- Check for data quality issues
SELECT 'clinical_trials_null_trial_id' as check_name, COUNT(*) as issue_count 
FROM clinical_trials WHERE trial_id IS NULL
UNION ALL
SELECT 'drug_safety_invalid_age' as check_name, COUNT(*) as issue_count 
FROM drug_safety WHERE age < 0 OR age > 150
UNION ALL
SELECT 'synthetic_ehr_null_patient_id' as check_name, COUNT(*) as issue_count 
FROM synthetic_ehr WHERE patient_id IS NULL;

-- =====================================================
-- USEFUL QUERIES FOR DATA EXPLORATION
-- =====================================================

-- Clinical trials by phase
SELECT phase, COUNT(*) as trial_count 
FROM clinical_trials 
WHERE phase IS NOT NULL 
GROUP BY phase 
ORDER BY trial_count DESC;

-- Drug safety reports by severity
SELECT serious, COUNT(*) as report_count 
FROM drug_safety 
GROUP BY serious;

-- Most common drug classes
SELECT drug_class, COUNT(*) as drug_count 
FROM drug_ontology 
WHERE drug_class IS NOT NULL 
GROUP BY drug_class 
ORDER BY drug_count DESC 
LIMIT 10;

-- EHR visits by age group
SELECT 
    CASE 
        WHEN age < 18 THEN 'Pediatric'
        WHEN age BETWEEN 18 AND 65 THEN 'Adult'
        ELSE 'Elderly'
    END as age_group,
    COUNT(*) as visit_count
FROM synthetic_ehr 
WHERE age IS NOT NULL
GROUP BY age_group;

-- =====================================================
-- FOREIGN KEY RELATIONSHIPS (Optional)
-- =====================================================

-- If you want to establish relationships between tables, uncomment these:

-- Add foreign key from drug_safety to drug_ontology
-- ALTER TABLE drug_safety 
-- ADD CONSTRAINT fk_drug_safety_drug_name 
-- FOREIGN KEY (drug_name) REFERENCES drug_ontology(drug_name);

-- Note: This assumes drug names match exactly between tables
-- You may need to clean and standardize drug names first

-- =====================================================
-- GRANT PERMISSIONS (adjust as needed)
-- =====================================================

-- Grant permissions to a specific user (replace 'your_user' with actual username)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO your_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO your_user;