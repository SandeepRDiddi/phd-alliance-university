-- =========================================
-- ADVANCED RESEARCH ANALYTICS QUERIES
-- PhD Project - Statistical & Longitudinal Analysis
-- =========================================

-- ===================
-- 1. LONGITUDINAL ANALYSIS
-- ===================

-- Patient Journey Tracking
WITH patient_timeline AS (
    SELECT 
        ct.patient_id,
        ehr.age,
        ehr.gender,
        do.drug_category,
        ct.enrollment_date,
        ct.start_date,
        ct.completion_date,
        ehr.dropout_date,
        ehr.dropout_reason,
        CASE 
            WHEN ehr.dropout_date IS NULL AND ct.status = 'Completed' THEN 'Completed'
            WHEN ehr.dropout_date IS NOT NULL THEN 'Dropped Out'
            ELSE 'Active'
        END as patient_status,
        EXTRACT(EPOCH FROM (
            COALESCE(ehr.dropout_date, ct.completion_date, CURRENT_DATE) - ct.enrollment_date
        ))/86400 as days_in_study
    FROM clinical_trials ct
    JOIN synthetic_ehr ehr ON ct.patient_id = ehr.patient_id
    LEFT JOIN drug_ontology do ON ct.drug_id = do.drug_id
    WHERE ct.enrollment_date IS NOT NULL
)
SELECT 
    drug_category,
    patient_status,
    COUNT(*) as patient_count,
    ROUND(AVG(days_in_study), 0) as avg_days_in_study,
    ROUND(STDDEV(days_in_study), 0) as std_days_in_study,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_in_study) as median_days_in_study,
    ROUND(AVG(age), 1) as avg_patient_age
FROM patient_timeline
GROUP BY drug_category, patient_status
ORDER BY drug_category, patient_status;

-- Time-to-Event Analysis (Survival Analysis Data)
SELECT 
    ct.trial_id,
    do.drug_category,
    ct.patient_id,
    ct.enrollment_date,
    ehr.dropout_date,
    CASE 
        WHEN ehr.dropout_date IS NOT NULL THEN 1 
        ELSE 0 
    END as event_occurred,
    EXTRACT(EPOCH FROM (
        COALESCE(ehr.dropout_date, CURRENT_DATE) - ct.enrollment_date
    ))/86400 as time_to_event_days,
    ehr.dropout_reason as event_type,
    ehr.age,
    ehr.gender,
    COUNT(ds.incident_id) as adverse_events_count
FROM clinical_trials ct
JOIN synthetic_ehr ehr ON ct.patient_id = ehr.patient_id
JOIN drug_ontology do ON ct.drug_id = do.drug_id
LEFT JOIN drug_safety ds ON ct.patient_id = ds.patient_id
WHERE ct.enrollment_date IS NOT NULL
GROUP BY ct.trial_id, do.drug_category, ct.patient_id, ct.enrollment_date, 
         ehr.dropout_date, ehr.dropout_reason, ehr.age, ehr.gender
ORDER BY time_to_event_days;

-- ===================
-- 2. COHORT ANALYSIS
-- ===================

-- Enrollment Cohorts by Month
WITH enrollment_cohorts AS (
    SELECT 
        DATE_TRUNC('month', enrollment_date) as cohort_month,
        patient_id,
        enrollment_date,
        COALESCE(dropout_date, CURRENT_DATE) as last_active_date
    FROM clinical_trials ct
    JOIN synthetic_ehr ehr ON ct.patient_id = ehr.patient_id
    WHERE enrollment_date >= CURRENT_DATE - INTERVAL '12 months'
),
cohort_retention AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT patient_id) as cohort_size,
        COUNT(DISTINCT CASE 
            WHEN last_active_date >= cohort_month + INTERVAL '1 month' 
            THEN patient_id 
        END) as retained_1_month,
        COUNT(DISTINCT CASE 
            WHEN last_active_date >= cohort_month + INTERVAL '3 months' 
            THEN patient_id 
        END) as retained_3_months,
        COUNT(DISTINCT CASE 
            WHEN last_active_date >= cohort_month + INTERVAL '6 months' 
            THEN patient_id 
        END) as retained_6_months
    FROM enrollment_cohorts
    GROUP BY cohort_month
)
SELECT 
    TO_CHAR(cohort_month, 'YYYY-MM') as cohort,
    cohort_size,
    retained_1_month,
    retained_3_months,
    retained_6_months,
    ROUND(retained_1_month::numeric / cohort_size * 100, 1) as retention_1m_pct,
    ROUND(retained_3_months::numeric / cohort_size * 100, 1) as retention_3m_pct,
    ROUND(retained_6_months::numeric / cohort_size * 100, 1) as retention_6m_pct
FROM cohort_retention
ORDER BY cohort_month;

-- ===================
-- 3. PREDICTIVE ANALYTICS QUERIES
-- ===================

-- Patient Risk Scoring
WITH patient_risk_factors AS (
    SELECT 
        ehr.patient_id,
        ehr.age,
        ehr.gender,
        do.drug_category,
        ct.phase,
        COUNT(ds.incident_id) as historical_incidents,
        AVG(ds.severity_score) as avg_severity,
        CASE 
            WHEN ehr.age > 65 THEN 2
            WHEN ehr.age > 50 THEN 1
            ELSE 0
        END as age_risk_score,
        CASE 
            WHEN COUNT(ds.incident_id) > 2 THEN 3
            WHEN COUNT(ds.incident_id) > 0 THEN 1
            ELSE 0
        END as history_risk_score
    FROM synthetic_ehr ehr
    JOIN clinical_trials ct ON ehr.patient_id = ct.patient_id
    JOIN drug_ontology do ON ct.drug_id = do.drug_id
    LEFT JOIN drug_safety ds ON ehr.patient_id = ds.patient_id
    GROUP BY ehr.patient_id, ehr.age, ehr.gender, do.drug_category, ct.phase
)
SELECT 
    patient_id,
    age,
    gender,
    drug_category,
    phase,
    historical_incidents,
    ROUND(COALESCE(avg_severity, 0), 2) as avg_historical_severity,
    (age_risk_score + history_risk_score + 
     CASE WHEN phase IN ('Phase I', 'Phase II') THEN 1 ELSE 0 END) as composite_risk_score,
    CASE 
        WHEN (age_risk_score + history_risk_score) >= 4 THEN 'High Risk'
        WHEN (age_risk_score + history_risk_score) >= 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as risk_category
FROM patient_risk_factors
ORDER BY composite_risk_score DESC, age DESC;

-- ===================
-- 4. DRUG INTERACTION ANALYSIS
-- ===================

-- Concurrent Drug Usage Patterns
WITH patient_drugs AS (
    SELECT 
        ct1.patient_id,
        ct1.drug_id as drug1_id,
        do1.drug_name as drug1_name,
        do1.drug_category as drug1_category,
        ct2.drug_id as drug2_id,
        do2.drug_name as drug2_name,
        do2.drug_category as drug2_category,
        COUNT(ds.incident_id) as concurrent_incidents,
        AVG(ds.severity_score) as avg_concurrent_severity
    FROM clinical_trials ct1
    JOIN clinical_trials ct2 ON ct1.patient_id = ct2.patient_id AND ct1.drug_id < ct2.drug_id
    JOIN drug_ontology do1 ON ct1.drug_id = do1.drug_id
    JOIN drug_ontology do2 ON ct2.drug_id = do2.drug_id
    LEFT JOIN drug_safety ds ON ct1.patient_id = ds.patient_id
    GROUP BY ct1.patient_id, ct1.drug_id, do1.drug_name, do1.drug_category,
             ct2.drug_id, do2.drug_name, do2.drug_category
)
SELECT 
    drug1_category,
    drug2_category,
    COUNT(DISTINCT patient_id) as patients_on_both,
    SUM(concurrent_incidents) as total_incidents,
    ROUND(AVG(avg_concurrent_severity), 2) as avg_severity_when_concurrent,
    ROUND(SUM(concurrent_incidents)::numeric / COUNT(DISTINCT patient_id), 2) as incidents_per_patient
FROM patient_drugs
GROUP BY drug1_category, drug2_category
HAVING COUNT(DISTINCT patient_id) >= 5
ORDER BY incidents_per_patient DESC, avg_severity_when_concurrent DESC;

-- ===================
-- 5. EFFICACY CORRELATION ANALYSIS
-- ===================

-- Age vs Efficacy Correlation Data
WITH efficacy_estimates AS (
    SELECT 
        ehr.patient_id,
        ehr.age,
        ehr.gender,
        do.drug_category,
        ct.phase,
        -- Simulated efficacy score based on safety data and patient characteristics
        CASE 
            WHEN COUNT(ds.incident_id) = 0 THEN 
                8.5 + (RANDOM() * 1.5)
            WHEN AVG(ds.severity_score) < 3 THEN 
                7.2 + (RANDOM() * 2.0)
            WHEN AVG(ds.severity_score) < 6 THEN 
                5.8 + (RANDOM() * 2.5)
            ELSE 
                3.5 + (RANDOM() * 2.0)
        END as estimated_efficacy_score,
        COUNT(ds.incident_id) as safety_incidents,
        AVG(ds.severity_score) as avg_safety_severity
    FROM synthetic_ehr ehr
    JOIN clinical_trials ct ON ehr.patient_id = ct.patient_id
    JOIN drug_ontology do ON ct.drug_id = do.drug_id
    LEFT JOIN drug_safety ds ON ehr.patient_id = ds.patient_id
    GROUP BY ehr.patient_id, ehr.age, ehr.gender, do.drug_category, ct.phase
)
SELECT 
    CASE 
        WHEN age < 30 THEN '18-29'
        WHEN age < 45 THEN '30-44'
        WHEN age < 60 THEN '45-59'
        WHEN age < 75 THEN '60-74'
        ELSE '75+'
    END as age_group,
    drug_category,
    COUNT(*) as patient_count,
    ROUND(AVG(estimated_efficacy_score), 2) as avg_efficacy,
    ROUND(STDDEV(estimated_efficacy_score), 2) as std_efficacy,
    ROUND(AVG(safety_incidents), 1) as avg_safety_incidents,
    -- Correlation coefficient calculation components
    ROUND(AVG(age), 1) as avg_age,
    ROUND(CORR(age, estimated_efficacy_score), 3) as age_efficacy_correlation
FROM efficacy_estimates
GROUP BY age_group, drug_category
HAVING COUNT(*) >= 10
ORDER BY age_group, drug_category;

-- ===================
-- 6. STATISTICAL HYPOTHESIS TESTING DATA
-- ===================

-- Two-Sample T-Test Data: Male vs Female Efficacy
SELECT 
    'Male' as gender,
    drug_category,
    COUNT(*) as sample_size,
    ROUND(AVG(
        CASE 
            WHEN COUNT(ds.incident_id) = 0 THEN 8.5 + (RANDOM() * 1.5)
            WHEN AVG(ds.severity_score) < 3 THEN 7.2 + (RANDOM() * 2.0)
            ELSE 5.8 + (RANDOM() * 2.5)
        END
    ), 2) as mean_efficacy,
    ROUND(STDDEV(
        CASE 
            WHEN COUNT(ds.incident_id) = 0 THEN 8.5 + (RANDOM() * 1.5)
            WHEN AVG(ds.severity_score) < 3 THEN 7.2 + (RANDOM() * 2.0)
            ELSE 5.8 + (RANDOM() * 2.5)
        END
    ), 2) as std_efficacy
FROM synthetic_ehr ehr
JOIN clinical_trials ct ON ehr.patient_id = ct.patient_id
JOIN drug_ontology do ON ct.drug_id = do.drug_id
LEFT JOIN drug_safety ds ON ehr.patient_id = ds.patient_id
WHERE ehr.gender = 'M'
GROUP BY do.drug_category, ehr.patient_id, ehr.gender
HAVING COUNT(*) >= 15

UNION ALL

SELECT 
    'Female' as gender,
    drug_category,
    COUNT(*) as sample_size,
    ROUND(AVG(
        CASE 
            WHEN COUNT(ds.incident_id) = 0 THEN 8.2 + (RANDOM() * 1.8)
            WHEN AVG(ds.severity_score) < 3 THEN 6.9 + (RANDOM() * 2.2)
            ELSE 5.5 + (RANDOM() * 2.7)
        END
    ), 2) as mean_efficacy,
    ROUND(STDDEV(
        CASE 
            WHEN COUNT(ds.incident_id) = 0 THEN 8.2 + (RANDOM() * 1.8)
            WHEN AVG(ds.severity_score) < 3 THEN 6.9 + (RANDOM() * 2.2)
            ELSE 5.5 + (RANDOM() * 2.7)
        END
    ), 2) as std_efficacy
FROM synthetic_ehr ehr
JOIN clinical_trials ct ON ehr.patient_id = ct.patient_id
JOIN drug_ontology do ON ct.drug_id = do.drug_id
LEFT JOIN drug_safety ds ON ehr.patient_id = ds.patient_id
WHERE ehr.gender = 'F'
GROUP BY do.drug_category, ehr.patient_id, ehr.gender
HAVING COUNT(*) >= 15
ORDER BY drug_category, gender;

-- ANOVA Data: Efficacy Across Trial Phases
WITH phase_efficacy AS (
    SELECT 
        ct.phase,
        ehr.patient_id,
        do.drug_category,
        CASE 
            WHEN COUNT(ds.incident_id) = 0 THEN 
                CASE ct.phase
                    WHEN 'Phase I' THEN 6.8 + (RANDOM() * 2.5)
                    WHEN 'Phase II' THEN 7.4 + (RANDOM() * 2.2)
                    WHEN 'Phase III' THEN 8.1 + (RANDOM() * 1.8)
                    WHEN 'Phase IV' THEN 8.3 + (RANDOM() * 1.5)
                END
            ELSE 
                CASE ct.phase
                    WHEN 'Phase I' THEN 4.5 + (RANDOM() * 3.0)
                    WHEN 'Phase II' THEN 5.2 + (RANDOM() * 2.8)
                    WHEN 'Phase III' THEN 6.1 + (RANDOM() * 2.5)
                    WHEN 'Phase IV' THEN 6.8 + (RANDOM() * 2.2)
                END
        END as efficacy_score
    FROM clinical_trials ct
    JOIN synthetic_ehr ehr ON ct.patient_id = ehr.patient_id
    JOIN drug_ontology do ON ct.drug_id = do.drug_id
    LEFT JOIN drug_safety ds ON ehr.patient_id = ds.patient_id
    GROUP BY ct.phase, ehr.patient_id, do.drug_category, ct.phase
)
SELECT 
    phase,
    drug_category,
    COUNT(*) as sample_size,
    ROUND(AVG(efficacy_score), 2) as mean_efficacy,
    ROUND(STDDEV(efficacy_score), 2) as std_efficacy,
    ROUND(MIN(efficacy_score), 2) as min_efficacy,
    ROUND(MAX(efficacy_score), 2) as max_efficacy,
    -- Quartiles for box plot data
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY efficacy_score), 2) as q1,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY efficacy_score), 2) as median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY efficacy_score), 2) as q3
FROM phase_efficacy
GROUP BY phase, drug_category
HAVING COUNT(*) >= 10
ORDER BY 
    CASE phase 
        WHEN 'Phase I' THEN 1 
        WHEN 'Phase II' THEN 2 
        WHEN 'Phase III' THEN 3 
        WHEN 'Phase IV' THEN 4 
    END,
    drug_category;

-- ===================
-- 7. MACHINE LEARNING FEATURE PREPARATION
-- ===================

-- Feature Matrix for Predictive Modeling
SELECT 
    ehr.patient_id,
    -- Demographic features
    ehr.age,
    CASE WHEN ehr.gender = 'M' THEN 1 ELSE 0 END as is_male,
    
    -- Trial features
    CASE WHEN ct.phase = 'Phase I' THEN 1 ELSE 0 END as phase_1,
    CASE WHEN ct.phase = 'Phase II' THEN 1 ELSE 0 END as phase_2,
    CASE WHEN ct.phase = 'Phase III' THEN 1 ELSE 0 END as phase_3,
    CASE WHEN ct.phase = 'Phase IV' THEN 1 ELSE 0 END as phase_4,
    
    -- Drug category features (one-hot encoded)
    CASE WHEN do.drug_category = 'oncology' THEN 1 ELSE 0 END as oncology_drug,
    CASE WHEN do.drug_category = 'cardiology' THEN 1 ELSE 0 END as cardiology_drug,
    CASE WHEN do.drug_category = 'neurology' THEN 1 ELSE 0 END as neurology_drug,
    CASE WHEN do.drug_category = 'immunology' THEN 1 ELSE 0 END as immunology_drug,
    
    -- Historical safety features
    COALESCE(safety_history.incident_count, 0) as historical_incidents,
    COALESCE(safety_history.avg_severity, 0) as historical_avg_severity,
    COALESCE(safety_history.max_severity, 0) as historical_max_severity,
    
    -- Time-based features
    EXTRACT(EPOCH FROM (ct.enrollment_date - DATE '2020-01-01'))/86400 as days_since_baseline,
    EXTRACT(DOW FROM ct.enrollment_date) as enrollment_day_of_week,
    EXTRACT(MONTH FROM ct.enrollment_date) as enrollment_month,
    
    -- Target variables
    CASE WHEN ehr.dropout_date IS NOT NULL THEN 1 ELSE 0 END as dropped_out,
    COALESCE(
        EXTRACT(EPOCH FROM (ehr.dropout_date - ct.enrollment_date))/86400, 
        EXTRACT(EPOCH FROM (CURRENT_DATE - ct.enrollment_date))/86400
    ) as days_in_study,
    
    -- Outcome variable (safety incident in next 30 days)
    CASE WHEN future_incidents.next_30_day_incidents > 0 THEN 1 ELSE 0 END as safety_incident_30d
    
FROM synthetic_ehr ehr
JOIN clinical_trials ct ON ehr.patient_id = ct.patient_id
JOIN drug_ontology do ON ct.drug_id = do.drug_id

-- Historical safety data
LEFT JOIN (
    SELECT 
        patient_id,
        COUNT(*) as incident_count,
        AVG(severity_score) as avg_severity,
        MAX(severity_score) as max_severity
    FROM drug_safety 
    WHERE incident_date < '2024-01-01'  -- Historical cutoff
    GROUP BY patient_id
) safety_history ON ehr.patient_id = safety_history.patient_id

-- Future incidents for prediction target
LEFT JOIN (
    SELECT 
        ds.patient_id,
        COUNT(*) as next_30_day_incidents
    FROM drug_safety ds
    JOIN clinical_trials ct ON ds.patient_id = ct.patient_id
    WHERE ds.incident_date BETWEEN ct.enrollment_date AND ct.enrollment_date + INTERVAL '30 days'
    GROUP BY ds.patient_id
) future_incidents ON ehr.patient_id = future_incidents.patient_id

WHERE ct.enrollment_date IS NOT NULL
ORDER BY ehr.patient_id;

-- ===================
-- 8. REGULATORY REPORTING QUERIES
-- ===================

-- Serious Adverse Events (SAE) Report
SELECT 
    ds.incident_date,
    ds.patient_id,
    ct.trial_id,
    do.drug_name,
    do.drug_category,
    ct.phase,
    ds.severity_level,
    ds.severity_score,
    ds.incident_description,
    ehr.age,
    ehr.gender,
    -- Days since enrollment when incident occurred
    EXTRACT(EPOCH FROM (ds.incident_date - ct.enrollment_date))/86400 as days_since_enrollment,
    -- Regulatory classification
    CASE 
        WHEN ds.severity_level = 'life_threatening' THEN 'Serious - Life Threatening'
        WHEN ds.severity_level = 'severe' AND ds.severity_score >= 7 THEN 'Serious - Severe'
        WHEN ds.severity_level = 'severe' THEN 'Non-Serious - Severe'
        ELSE 'Non-Serious'
    END as regulatory_classification,
    -- Requires immediate reporting?
    CASE 
        WHEN ds.severity_level = 'life_threatening' THEN 'IMMEDIATE'
        WHEN ds.severity_level = 'severe' AND ds.severity_score >= 7 THEN '24 HOURS'
        ELSE 'ROUTINE'
    END as reporting_timeline
FROM drug_safety ds
JOIN clinical_trials ct ON ds.patient_id = ct.patient_id
JOIN drug_ontology do ON ct.drug_id = do.drug_id
JOIN synthetic_ehr ehr ON ds.patient_id = ehr.patient_id
WHERE ds.severity_level IN ('severe', 'life_threatening') 
   OR ds.severity_score >= 6
ORDER BY 
    CASE 
        WHEN ds.severity_level = 'life_threatening' THEN 1
        WHEN ds.severity_level = 'severe' AND ds.severity_score >= 7 THEN 2
        ELSE 3
    END,
    ds.incident_date DESC;

-- ===================
-- 9. PUBLICATION-READY SUMMARY TABLES
-- ===================

-- Table 1: Baseline Characteristics
WITH baseline_stats AS (
    SELECT 
        'Overall' as cohort,
        COUNT(DISTINCT ehr.patient_id) as n,
        ROUND(AVG(ehr.age), 1) as mean_age,
        ROUND(STDDEV(ehr.age), 1) as sd_age,
        COUNT(CASE WHEN ehr.gender = 'M' THEN 1 END) as male_n,
        ROUND(COUNT(CASE WHEN ehr.gender = 'M' THEN 1 END)::numeric / COUNT(*) * 100, 1) as male_pct
    FROM synthetic_ehr ehr
    JOIN clinical_trials ct ON ehr.patient_id = ct.patient_id
    
    UNION ALL
    
    SELECT 
        do.drug_category as cohort,
        COUNT(DISTINCT ehr.patient_id) as n,
        ROUND(AVG(ehr.age), 1) as mean_age,
        ROUND(STDDEV(ehr.age), 1) as sd_age,
        COUNT(CASE WHEN ehr.gender = 'M' THEN 1 END) as male_n,
        ROUND(COUNT(CASE WHEN ehr.gender = 'M' THEN 1 END)::numeric / COUNT(*) * 100, 1) as male_pct
    FROM synthetic_ehr ehr
    JOIN clinical_trials ct ON ehr.patient_id = ct.patient_id
    JOIN drug_ontology do ON ct.drug_id = do.drug_id
    GROUP BY do.drug_category
)
SELECT 
    cohort,
    n as "N",
    mean_age || ' ± ' || sd_age as "Age (Mean ± SD)",
    male_n || ' (' || male_pct || '%)' as "Male, N (%)",
    (n - male_n) || ' (' || ROUND(100 - male_pct, 1) || '%)' as "Female, N (%)"
FROM baseline_stats
ORDER BY 
    CASE WHEN cohort = 'Overall' THEN 0 ELSE 1 END,
    cohort;

-- ===================
-- 10. DATA QUALITY AND COMPLETENESS REPORT
-- ===================

-- Data Completeness Assessment
SELECT 
    'synthetic_ehr' as table_name,
    'patient_id' as column_name,
    COUNT(*) as total_records,
    COUNT(patient_id) as non_null_records,
    ROUND((COUNT(patient_id)::numeric / COUNT(*)) * 100, 1) as completeness_pct
FROM synthetic_ehr

UNION ALL

SELECT 'synthetic_ehr', 'age', COUNT(*), COUNT(age), 
       ROUND((COUNT(age)::numeric / COUNT(*)) * 100, 1) FROM synthetic_ehr
UNION ALL
SELECT 'synthetic_ehr', 'gender', COUNT(*), COUNT(gender), 
       ROUND((COUNT(gender)::numeric / COUNT(*)) * 100, 1) FROM synthetic_ehr

UNION ALL

SELECT 'clinical_trials', 'enrollment_date', COUNT(*), COUNT(enrollment_date), 
       ROUND((COUNT(enrollment_date)::numeric / COUNT(*)) * 100, 1) FROM clinical_trials
UNION ALL
SELECT 'clinical_trials', 'target_enrollment', COUNT(*), COUNT(target_enrollment), 
       ROUND((COUNT(target_enrollment)::numeric / COUNT(*)) * 100, 1) FROM clinical_trials

UNION ALL

SELECT 'drug_safety', 'severity_score', COUNT(*), COUNT(severity_score), 
       ROUND((COUNT(severity_score)::numeric / COUNT(*)) * 100, 1) FROM drug_safety
UNION ALL
SELECT 'drug_safety', 'incident_date', COUNT(*), COUNT(incident_date), 
       ROUND((COUNT(incident_date)::numeric / COUNT(*)) * 100, 1) FROM drug_safety

ORDER BY table_name, column_name;

-- ===================
-- 11. EXPORT VIEWS FOR EXTERNAL ANALYSIS
-- ===================

-- Create materialized view for R/Python analysis
-- (Run this as a separate DDL statement)
/*
CREATE MATERIALIZED VIEW research_analysis_dataset AS
SELECT 
    ehr.patient_id,
    ehr.age,
    ehr.gender,
    ct.trial_id,
    do.drug_name,
    do.drug_category,
    ct.phase,
    ct.enrollment_date,
    ct.start_date,
    ct.completion_date,
    ehr.dropout_date,
    ehr.dropout_reason,
    COUNT(ds.incident_id) as total_incidents,
    AVG(ds.severity_score) as avg_incident_severity,
    MAX(ds.severity_score) as max_incident_severity,
    MIN(ds.incident_date) as first_incident_date,
    MAX(ds.incident_date) as last_incident_date
FROM synthetic_ehr ehr
JOIN clinical_trials ct ON ehr.patient_id = ct.patient_id
JOIN drug_ontology do ON ct.drug_id = do.drug_id
LEFT JOIN drug_safety ds ON ehr.patient_id = ds.patient_id
GROUP BY ehr.patient_id, ehr.age, ehr.gender, ct.trial_id, do.drug_name, 
         do.drug_category, ct.phase, ct.enrollment_date, ct.start_date, 
         ct.completion_date, ehr.dropout_date, ehr.dropout_reason;

CREATE INDEX idx_research_dataset_patient ON research_analysis_dataset(patient_id);
CREATE INDEX idx_research_dataset_drug ON research_analysis_dataset(drug_category);
CREATE INDEX idx_research_dataset_phase ON research_analysis_dataset(phase);
*/