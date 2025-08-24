-- =====================================================
-- DATABASE RELATIONSHIPS IMPLEMENTATION
-- Medical/Pharmaceutical Database Enhancement
-- =====================================================

-- =====================================================
-- SECTION 1: CREATE REFERENCE TABLES
-- =====================================================

-- Create standardized conditions/diagnoses reference table
CREATE TABLE conditions (
    condition_id SERIAL PRIMARY KEY,
    condition_name VARCHAR(255) UNIQUE NOT NULL,
    icd_code VARCHAR(20),
    category VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create drug categories reference table for better classification
CREATE TABLE drug_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(255) UNIQUE NOT NULL,
    parent_category_id INTEGER REFERENCES drug_categories(category_id),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SECTION 2: ADD FOREIGN KEY COLUMNS
-- =====================================================

-- Add foreign key columns to existing tables
ALTER TABLE drug_safety ADD COLUMN drug_id VARCHAR(50);
ALTER TABLE drug_safety ADD COLUMN condition_id INTEGER;

ALTER TABLE synthetic_ehr ADD COLUMN drug_id VARCHAR(50);
ALTER TABLE synthetic_ehr ADD COLUMN condition_id INTEGER;

ALTER TABLE clinical_trials ADD COLUMN condition_id INTEGER;

-- =====================================================
-- SECTION 3: POPULATE REFERENCE TABLES
-- =====================================================

-- Populate conditions table with unique conditions from all tables
INSERT INTO conditions (condition_name)
SELECT DISTINCT condition FROM clinical_trials
WHERE condition IS NOT NULL
UNION
SELECT DISTINCT diagnosis FROM synthetic_ehr
WHERE diagnosis IS NOT NULL
ON CONFLICT (condition_name) DO NOTHING;

-- Add common ICD codes and categories for major conditions
UPDATE conditions SET icd_code = 'E11', category = 'Endocrine' WHERE condition_name = 'Diabetes';
UPDATE conditions SET icd_code = 'I10', category = 'Cardiovascular' WHERE condition_name = 'Hypertension';
UPDATE conditions SET icd_code = 'J45', category = 'Respiratory' WHERE condition_name = 'Asthma';
UPDATE conditions SET icd_code = 'C50', category = 'Oncology' WHERE condition_name = 'Breast Cancer';
UPDATE conditions SET icd_code = 'U07.1', category = 'Infectious' WHERE condition_name = 'COVID-19';
UPDATE conditions SET icd_code = 'F03', category = 'Neurological' WHERE condition_name = 'Alzheimer''s';
UPDATE conditions SET icd_code = 'B20', category = 'Infectious' WHERE condition_name = 'HIV';
UPDATE conditions SET icd_code = 'C78', category = 'Oncology' WHERE condition_name = 'Cancer';
UPDATE conditions SET icd_code = 'J44', category = 'Respiratory' WHERE condition_name = 'COPD';
UPDATE conditions SET icd_code = 'I50', category = 'Cardiovascular' WHERE condition_name = 'Heart Failure';
UPDATE conditions SET icd_code = 'I63', category = 'Cardiovascular' WHERE condition_name = 'Stroke';

-- Populate drug categories
INSERT INTO drug_categories (category_name, description) VALUES
('Cardiovascular', 'Drugs affecting the cardiovascular system'),
('Endocrine', 'Hormonal and metabolic drugs'),
('Infectious Disease', 'Antimicrobial and antiviral agents'),
('Oncology', 'Cancer treatment drugs'),
('Respiratory', 'Drugs for respiratory conditions'),
('Analgesic', 'Pain relief medications'),
('Neurological', 'CNS and neurological drugs');

-- =====================================================
-- SECTION 4: UPDATE FOREIGN KEY VALUES
-- =====================================================

-- Link drug_safety records to drug_ontology via drug names
UPDATE drug_safety 
SET drug_id = (
    SELECT drug_id 
    FROM drug_ontology 
    WHERE drug_ontology.generic_name = drug_safety.drug_name
    LIMIT 1
);

-- Link drug_safety records to conditions
UPDATE drug_safety 
SET condition_id = (
    SELECT condition_id 
    FROM conditions 
    WHERE condition_name IN (
        -- Map common drug uses to conditions
        CASE drug_safety.drug_name
            WHEN 'Metformin' THEN 'Diabetes'
            WHEN 'Insulin' THEN 'Diabetes'
            WHEN 'Atorvastatin' THEN 'Hypertension'
            WHEN 'Amlodipine' THEN 'Hypertension'
            WHEN 'Aspirin' THEN 'Hypertension'
            WHEN 'Remdesivir' THEN 'COVID-19'
            WHEN 'Paracetamol' THEN 'Pain'
        END
    )
);

-- Link synthetic_ehr to conditions
UPDATE synthetic_ehr 
SET condition_id = (
    SELECT condition_id 
    FROM conditions 
    WHERE conditions.condition_name = synthetic_ehr.diagnosis
);

-- Link synthetic_ehr to drugs (when treatment is a known drug)
UPDATE synthetic_ehr 
SET drug_id = (
    SELECT drug_id 
    FROM drug_ontology 
    WHERE drug_ontology.generic_name = synthetic_ehr.treatment
    LIMIT 1
);

-- Link clinical_trials to conditions
UPDATE clinical_trials 
SET condition_id = (
    SELECT condition_id 
    FROM conditions 
    WHERE conditions.condition_name = clinical_trials.condition
);

-- =====================================================
-- SECTION 5: CREATE FOREIGN KEY CONSTRAINTS
-- =====================================================

-- Add foreign key constraints
ALTER TABLE drug_safety 
ADD CONSTRAINT fk_drug_safety_drug 
FOREIGN KEY (drug_id) REFERENCES drug_ontology(drug_id);

ALTER TABLE drug_safety 
ADD CONSTRAINT fk_drug_safety_condition 
FOREIGN KEY (condition_id) REFERENCES conditions(condition_id);

ALTER TABLE synthetic_ehr 
ADD CONSTRAINT fk_synthetic_ehr_drug 
FOREIGN KEY (drug_id) REFERENCES drug_ontology(drug_id);

ALTER TABLE synthetic_ehr 
ADD CONSTRAINT fk_synthetic_ehr_condition 
FOREIGN KEY (condition_id) REFERENCES conditions(condition_id);

ALTER TABLE clinical_trials 
ADD CONSTRAINT fk_clinical_trials_condition 
FOREIGN KEY (condition_id) REFERENCES conditions(condition_id);

-- =====================================================
-- SECTION 6: CREATE USEFUL INDEXES
-- =====================================================

-- Create indexes for better query performance
CREATE INDEX idx_drug_safety_drug_id ON drug_safety(drug_id);
CREATE INDEX idx_drug_safety_condition_id ON drug_safety(condition_id);
CREATE INDEX idx_drug_safety_report_date ON drug_safety(report_date);
CREATE INDEX idx_drug_safety_serious ON drug_safety(serious);

CREATE INDEX idx_synthetic_ehr_drug_id ON synthetic_ehr(drug_id);
CREATE INDEX idx_synthetic_ehr_condition_id ON synthetic_ehr(condition_id);
CREATE INDEX idx_synthetic_ehr_visit_date ON synthetic_ehr(visit_date);

CREATE INDEX idx_clinical_trials_condition_id ON clinical_trials(condition_id);
CREATE INDEX idx_clinical_trials_status ON clinical_trials(status);
CREATE INDEX idx_clinical_trials_phase ON clinical_trials(phase);

CREATE INDEX idx_drug_ontology_generic_name ON drug_ontology(generic_name);
CREATE INDEX idx_drug_ontology_drug_class ON drug_ontology(drug_class);

-- =====================================================
-- SECTION 7: CREATE USEFUL VIEWS
-- =====================================================

-- Create comprehensive drug safety view
CREATE OR REPLACE VIEW v_drug_safety_detailed AS
SELECT 
    ds.id,
    ds.report_id,
    ds.drug_name,
    do.drug_id,
    do.drug_class,
    do.mechanism_of_action,
    do.route_of_administration,
    do.approved,
    ds.adverse_event,
    ds.serious,
    ds.outcome,
    ds.report_date,
    ds.age,
    ds.gender,
    ds.country,
    c.condition_name,
    c.category as condition_category,
    c.icd_code
FROM drug_safety ds
LEFT JOIN drug_ontology do ON ds.drug_id = do.drug_id
LEFT JOIN conditions c ON ds.condition_id = c.condition_id;

-- Create clinical trials with conditions view
CREATE OR REPLACE VIEW v_clinical_trials_detailed AS
SELECT 
    ct.trial_id,
    ct.title,
    ct.condition,
    c.condition_name as standardized_condition,
    c.category as condition_category,
    c.icd_code,
    ct.intervention,
    ct.phase,
    ct.status,
    ct.start_date,
    ct.end_date,
    ct.location,
    ct.sponsor,
    CASE 
        WHEN ct.end_date < CURRENT_DATE THEN ct.end_date - ct.start_date 
        ELSE NULL 
    END as duration_days
FROM clinical_trials ct
LEFT JOIN conditions c ON ct.condition_id = c.condition_id;

-- Create patient treatment outcomes view
CREATE OR REPLACE VIEW v_patient_outcomes AS
SELECT 
    se.patient_id,
    se.age,
    se.gender,
    se.diagnosis,
    c.category as condition_category,
    se.treatment,
    do.drug_class,
    do.mechanism_of_action,
    se.outcome,
    se.visit_date,
    se.lab_result
FROM synthetic_ehr se
LEFT JOIN conditions c ON se.condition_id = c.condition_id
LEFT JOIN drug_ontology do ON se.drug_id = do.drug_id;

-- =====================================================
-- SECTION 8: ANALYTICAL QUERIES
-- =====================================================

-- Query 1: Drug Safety Analysis by Drug Class
SELECT 
    'Drug Safety by Class' as report_name,
    do.drug_class,
    COUNT(*) as total_reports,
    COUNT(CASE WHEN ds.serious = true THEN 1 END) as serious_reports,
    ROUND(COUNT(CASE WHEN ds.serious = true THEN 1 END) * 100.0 / COUNT(*), 2) as serious_percentage,
    COUNT(DISTINCT ds.adverse_event) as unique_adverse_events,
    COUNT(DISTINCT ds.drug_name) as unique_drugs
FROM drug_safety ds
INNER JOIN drug_ontology do ON ds.drug_id = do.drug_id
GROUP BY do.drug_class
ORDER BY total_reports DESC;

-- Query 2: Top Adverse Events by Condition Category
SELECT 
    'Top Adverse Events by Condition' as report_name,
    c.category as condition_category,
    ds.adverse_event,
    COUNT(*) as event_count,
    COUNT(DISTINCT ds.drug_name) as drugs_involved,
    ROUND(AVG(ds.age), 1) as avg_patient_age
FROM drug_safety ds
INNER JOIN conditions c ON ds.condition_id = c.condition_id
GROUP BY c.category, ds.adverse_event
HAVING COUNT(*) > 50
ORDER BY c.category, event_count DESC;

-- Query 3: Clinical Trial Success Analysis
SELECT 
    'Clinical Trial Analysis' as report_name,
    c.category as condition_category,
    ct.phase,
    ct.status,
    COUNT(*) as trial_count,
    COUNT(DISTINCT ct.sponsor) as unique_sponsors,
    ROUND(AVG(EXTRACT(YEAR FROM age(COALESCE(ct.end_date, CURRENT_DATE), ct.start_date))), 1) as avg_duration_years
FROM clinical_trials ct
INNER JOIN conditions c ON ct.condition_id = c.condition_id
WHERE ct.start_date IS NOT NULL
GROUP BY c.category, ct.phase, ct.status
ORDER BY c.category, ct.phase, trial_count DESC;

-- Query 4: Treatment Effectiveness Analysis
SELECT 
    'Treatment Effectiveness' as report_name,
    c.category as condition_category,
    do.drug_class,
    se.outcome,
    COUNT(*) as patient_count,
    ROUND(AVG(se.age), 1) as avg_age,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY c.category, do.drug_class) as outcome_percentage
FROM synthetic_ehr se
INNER JOIN conditions c ON se.condition_id = c.condition_id
INNER JOIN drug_ontology do ON se.drug_id = do.drug_id
GROUP BY c.category, do.drug_class, se.outcome
ORDER BY c.category, do.drug_class, patient_count DESC;

-- Query 5: Drug Safety Red Flags (High-Risk Combinations)
SELECT 
    'Drug Safety Red Flags' as report_name,
    ds.drug_name,
    do.drug_class,
    c.condition_name,
    ds.adverse_event,
    COUNT(*) as occurrence_count,
    ROUND(AVG(ds.age), 1) as avg_patient_age,
    COUNT(CASE WHEN ds.gender = 'Female' THEN 1 END) as female_count,
    COUNT(CASE WHEN ds.gender = 'Male' THEN 1 END) as male_count
FROM drug_safety ds
INNER JOIN drug_ontology do ON ds.drug_id = do.drug_id
INNER JOIN conditions c ON ds.condition_id = c.condition_id
WHERE ds.adverse_event IN ('Death', 'Liver Damage', 'Heart Attack', 'Stroke')
GROUP BY ds.drug_name, do.drug_class, c.condition_name, ds.adverse_event
HAVING COUNT(*) > 10
ORDER BY occurrence_count DESC;

-- Query 6: Comprehensive Drug Portfolio Analysis
SELECT 
    'Drug Portfolio Analysis' as report_name,
    do.drug_class,
    COUNT(DISTINCT do.drug_name) as total_drugs,
    COUNT(DISTINCT CASE WHEN do.approved = true THEN do.drug_name END) as approved_drugs,
    COUNT(DISTINCT ds.drug_name) as drugs_with_safety_reports,
    COUNT(DISTINCT se.treatment) as drugs_in_ehr,
    COALESCE(AVG(safety_stats.avg_reports), 0) as avg_safety_reports_per_drug
FROM drug_ontology do
LEFT JOIN drug_safety ds ON do.drug_id = ds.drug_id
LEFT JOIN synthetic_ehr se ON do.drug_id = se.drug_id
LEFT JOIN (
    SELECT drug_id, COUNT(*) as avg_reports
    FROM drug_safety 
    GROUP BY drug_id
) safety_stats ON do.drug_id = safety_stats.drug_id
GROUP BY do.drug_class
ORDER BY total_drugs DESC;

-- Query 7: Patient Demographics and Outcomes by Condition
SELECT 
    'Patient Demographics Analysis' as report_name,
    c.condition_name,
    se.gender,
    CASE 
        WHEN se.age < 18 THEN 'Pediatric'
        WHEN se.age BETWEEN 18 AND 65 THEN 'Adult'
        ELSE 'Elderly'
    END as age_group,
    COUNT(*) as patient_count,
    ROUND(AVG(se.age), 1) as avg_age,
    COUNT(CASE WHEN se.outcome = 'Improved' THEN 1 END) as improved_count,
    ROUND(COUNT(CASE WHEN se.outcome = 'Improved' THEN 1 END) * 100.0 / COUNT(*), 2) as improvement_rate
FROM synthetic_ehr se
INNER JOIN conditions c ON se.condition_id = c.condition_id
GROUP BY c.condition_name, se.gender, age_group
ORDER BY c.condition_name, patient_count DESC;

-- Query 8: Time-based Trend Analysis
SELECT 
    'Temporal Trends Analysis' as report_name,
    EXTRACT(YEAR FROM ds.report_date) as report_year,
    EXTRACT(QUARTER FROM ds.report_date) as report_quarter,
    c.category as condition_category,
    COUNT(*) as safety_reports,
    COUNT(DISTINCT ds.drug_name) as unique_drugs,
    COUNT(CASE WHEN ds.serious = true THEN 1 END) as serious_events
FROM drug_safety ds
INNER JOIN conditions c ON ds.condition_id = c.condition_id
WHERE ds.report_date IS NOT NULL 
    AND ds.report_date >= '2020-01-01'
GROUP BY report_year, report_quarter, c.category
ORDER BY report_year DESC, report_quarter DESC, safety_reports DESC;

-- =====================================================
-- SECTION 9: DATA QUALITY AND VALIDATION QUERIES
-- =====================================================

-- Data Quality Report
SELECT 
    'Data Quality Report' as report_name,
    'drug_safety' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN drug_id IS NULL THEN 1 END) as missing_drug_links,
    COUNT(CASE WHEN condition_id IS NULL THEN 1 END) as missing_condition_links
FROM drug_safety
UNION ALL
SELECT 
    'Data Quality Report',
    'synthetic_ehr',
    COUNT(*),
    COUNT(CASE WHEN drug_id IS NULL THEN 1 END),
    COUNT(CASE WHEN condition_id IS NULL THEN 1 END)
FROM synthetic_ehr
UNION ALL
SELECT 
    'Data Quality Report',
    'clinical_trials',
    COUNT(*),
    0,
    COUNT(CASE WHEN condition_id IS NULL THEN 1 END)
FROM clinical_trials;

-- =====================================================
-- SECTION 10: PERFORMANCE MONITORING QUERIES
-- =====================================================

-- Query to check relationship integrity
SELECT 
    'Relationship Integrity Check' as check_name,
    'drug_safety -> drug_ontology' as relationship,
    COUNT(*) as total_records,
    COUNT(drug_id) as linked_records,
    ROUND(COUNT(drug_id) * 100.0 / COUNT(*), 2) as link_percentage
FROM drug_safety
UNION ALL
SELECT 
    'Relationship Integrity Check',
    'synthetic_ehr -> drug_ontology',
    COUNT(*),
    COUNT(drug_id),
    ROUND(COUNT(drug_id) * 100.0 / COUNT(*), 2)
FROM synthetic_ehr
UNION ALL
SELECT 
    'Relationship Integrity Check',
    'clinical_trials -> conditions',
    COUNT(*),
    COUNT(condition_id),
    ROUND(COUNT(condition_id) * 100.0 / COUNT(*), 2)
FROM clinical_trials;

-- =====================================================
-- END OF SCRIPT
-- =====================================================

-- Instructions for use:
-- 1. Run sections 1-6 to create the relationship structure
-- 2. Run section 7 to create useful views
-- 3. Execute queries in section 8 for comprehensive analytics
-- 4. Use section 9 for data quality monitoring
-- 5. Use section 10 for relationship validation

-- Note: Adjust the UPDATE statements in Section 4 based on your actual data patterns
-- Some mappings might need customization based on your specific use case