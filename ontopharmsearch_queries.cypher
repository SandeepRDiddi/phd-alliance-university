//////////////////////////////////////////////////////////////////////////
// OntoPharmSearch Cypher Query Pack
// PhD Project – Semantic Search with Ontologies
//////////////////////////////////////////////////////////////////////////

// 1. List all nodes and relationships (sanity check)
MATCH (n)-[r]->(m)
RETURN n, r, m
LIMIT 20;

// 2. Find all dataset types represented
MATCH (d:Dataset)
RETURN DISTINCT d.type AS datasetType;

// 3. Get all original fields and their Dublin Core mappings
MATCH (f:Field)-[:MAPPED_TO]->(dc:DublinCore)
RETURN DISTINCT f.name AS originalField, dc.name AS dublinCoreField
LIMIT 50;

// 4. Retrieve all values normalized to SNOMED CT
MATCH (e:Entry)-[:HAS_VALUE]->(v:Value)-[:NORMALIZED_TO]->(c:Concept {ontology:"SNOMED CT"})
RETURN e.id AS entry, v.value AS value, c.code AS snomedCode
LIMIT 20;

// 5. Find all drugs linked to RxNorm
MATCH (d:Drug)-[:NORMALIZED_TO]->(c:Concept {ontology:"RxNorm"})
RETURN d.name AS drug, c.code AS rxnormCode
LIMIT 20;

// 6. Query EHR diagnoses
MATCH (p:Patient)-[:HAS_DIAGNOSIS]->(d:Diagnosis)-[:NORMALIZED_TO]->(c:Concept {ontology:"SNOMED CT"})
RETURN p.id AS patient, d.name AS diagnosis, c.code AS snomedCode
LIMIT 20;

// 7. Find potential adverse events for a given drug (e.g., Atorvastatin)
MATCH (d:Drug {name:"Atorvastatin"})-[:HAS_ADVERSE_EVENT]->(ae:AdverseEvent)-[:NORMALIZED_TO]->(c:Concept)
RETURN d.name AS drug, ae.name AS adverseEvent, c.code AS conceptCode
LIMIT 20;

// 8. Crosswalk: Clinical trial conditions → SNOMED
MATCH (t:Trial)-[:STUDIES_CONDITION]->(c1:Condition)-[:NORMALIZED_TO]->(c2:Concept {ontology:"SNOMED CT"})
RETURN t.id AS trial, c1.name AS condition, c2.code AS snomedCode
LIMIT 20;
