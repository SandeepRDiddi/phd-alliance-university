-- PostgreSQL DDL for Dataset Metadata Catalog
-- This table stores metadata about all fields in your medical datasets

-- =====================================================
-- DATASET METADATA CATALOG TABLE
-- =====================================================

CREATE TABLE dataset_metadata_catalog (
    id SERIAL PRIMARY KEY,
    dataset VARCHAR(100) NOT NULL,
    field VARCHAR(100) NOT NULL,
    datatype VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure unique combination of dataset and field
    CONSTRAINT unique_dataset_field UNIQUE (dataset, field)
);

-- Create indexes for better query performance
CREATE INDEX idx_metadata_dataset ON dataset_metadata_catalog(dataset);
CREATE INDEX idx_metadata_field ON dataset_metadata_catalog(field);
CREATE INDEX idx_metadata_datatype ON dataset_metadata_catalog(datatype);

-- Create a composite index for common queries
CREATE INDEX idx_metadata_dataset_field ON dataset_metadata_catalog(dataset, field);

-- =====================================================
-- DATA LOADING COMMAND
-- =====================================================

-- Load dataset metadata catalog
-- Note: Adjust the file path to match your local setup
COPY dataset_metadata_catalog (dataset, field, datatype, description)
FROM '/path/to/your/dataset_metadata_catalog.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- =====================================================
-- DATA VALIDATION QUERIES
-- =====================================================

-- Check record count
SELECT COUNT(*) as total_metadata_records FROM dataset_metadata_catalog;

-- Verify all datasets are present
SELECT dataset, COUNT(*) as field_count 
FROM dataset_metadata_catalog 
GROUP BY dataset 
ORDER BY dataset;

-- Check data types distribution
SELECT datatype, COUNT(*) as field_count 
FROM dataset_metadata_catalog 
GROUP BY datatype 
ORDER BY field_count DESC;

-- Look for any missing descriptions
SELECT dataset, field, datatype 
FROM dataset_metadata_catalog 
WHERE description IS NULL OR description = '';

-- =====================================================
-- USEFUL METADATA QUERIES
-- =====================================================

-- Get all fields for a specific dataset
SELECT field, datatype, description 
FROM dataset_metadata_catalog 
WHERE dataset = 'EHR'
ORDER BY field;

-- Find all string fields across datasets
SELECT dataset, field, description 
FROM dataset_metadata_catalog 
WHERE datatype = 'string'
ORDER BY dataset, field;

-- Find all date fields (useful for temporal analysis)
SELECT dataset, field, description 
FROM dataset_metadata_catalog 
WHERE datatype = 'date'
ORDER BY dataset, field;

-- Get metadata summary by dataset
SELECT 
    dataset,
    COUNT(*) as total_fields,
    COUNT(CASE WHEN datatype = 'string' THEN 1 END) as string_fields,
    COUNT(CASE WHEN datatype = 'integer' THEN 1 END) as integer_fields,
    COUNT(CASE WHEN datatype = 'float' THEN 1 END) as float_fields,
    COUNT(CASE WHEN datatype = 'date' THEN 1 END) as date_fields
FROM dataset_metadata_catalog 
GROUP BY dataset
ORDER BY dataset;

-- =====================================================
-- METADATA INTEGRITY FUNCTIONS
-- =====================================================

-- Function to validate if a field exists in a dataset
CREATE OR REPLACE FUNCTION field_exists(dataset_name VARCHAR, field_name VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM dataset_metadata_catalog 
        WHERE dataset = dataset_name AND field = field_name
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get field datatype
CREATE OR REPLACE FUNCTION get_field_datatype(dataset_name VARCHAR, field_name VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    field_type VARCHAR;
BEGIN
    SELECT datatype INTO field_type
    FROM dataset_metadata_catalog