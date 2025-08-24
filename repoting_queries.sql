-- Query 1: Drug Safety Analysis by Drug Class
SELECT 
    'Drug Safety by Class' as report_name,
    don.drug_class,
    COUNT(*) as total_reports,
    COUNT(CASE WHEN ds.serious = true THEN 1 END) as serious_reports,
    ROUND(COUNT(CASE WHEN ds.serious = true THEN 1 END) * 100.0 / COUNT(*), 2) as serious_percentage,
    COUNT(DISTINCT ds.adverse_event) as unique_adverse_events,
    COUNT(DISTINCT ds.drug_name) as unique_drugs
FROM drug_safety ds
INNER JOIN drug_ontology don ON ds.drug_id = don.drug_id
GROUP BY don.drug_class
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



-- Query 4: Treatment Effectiveness Analysis
SELECT 
    'Treatment Effectiveness' as report_name,
    c.category as condition_category,
    don.drug_class,
    se.outcome,
    COUNT(*) as patient_count,
    ROUND(AVG(se.age), 1) as avg_age,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY c.category, don.drug_class) as outcome_percentage
FROM synthetic_ehr se
INNER JOIN conditions c ON se.condition_id = c.condition_id
INNER JOIN drug_ontology don ON se.drug_id = don.drug_id
GROUP BY c.category, don.drug_class, se.outcome
ORDER BY c.category, don.drug_class, patient_count DESC;

-- Query 5: Drug Safety Red Flags (High-Risk Combinations)
SELECT 
    'Drug Safety Red Flags' as report_name,
    ds.drug_name,
    don.drug_class,
    c.condition_name,
    ds.adverse_event,
    COUNT(*) as occurrence_count,
    ROUND(AVG(ds.age), 1) as avg_patient_age,
    COUNT(CASE WHEN ds.gender = 'Female' THEN 1 END) as female_count,
    COUNT(CASE WHEN ds.gender = 'Male' THEN 1 END) as male_count
FROM drug_safety ds
INNER JOIN drug_ontology don ON ds.drug_id = don.drug_id
INNER JOIN conditions c ON ds.condition_id = c.condition_id
WHERE ds.adverse_event IN ('Death', 'Liver Damage', 'Heart Attack', 'Stroke')
GROUP BY ds.drug_name, don.drug_class, c.condition_name, ds.adverse_event
HAVING COUNT(*) > 10
ORDER BY occurrence_count DESC;

-- Query 6: Comprehensive Drug Portfolio Analysis
SELECT 
    'Drug Portfolio Analysis' as report_name,
    don.drug_class,
    COUNT(DISTINCT don.drug_name) as total_drugs,
    COUNT(DISTINCT CASE WHEN don.approved = true THEN don.drug_name END) as approved_drugs,
    COUNT(DISTINCT ds.drug_name) as drugs_with_safety_reports,
    COUNT(DISTINCT se.treatment) as drugs_in_ehr,
    COALESCE(AVG(safety_stats.avg_reports), 0) as avg_safety_reports_per_drug
FROM drug_ontology don
LEFT JOIN drug_safety ds ON don.drug_id = ds.drug_id
LEFT JOIN synthetic_ehr se ON don.drug_id = se.drug_id
LEFT JOIN (
    SELECT drug_id, COUNT(*) as avg_reports
    FROM drug_safety 
    GROUP BY drug_id
) safety_stats ON don.drug_id = safety_stats.drug_id
GROUP BY don.drug_class
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
