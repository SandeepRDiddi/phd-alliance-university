//////////////////////////////////////////////////////////////////////////
// OntoPharmSearch Analytics Query Pack
// PhD Project – Semantic Search with Ontologies
//////////////////////////////////////////////////////////////////////////

// 1. Count nodes and relationships by type
MATCH (n) RETURN labels(n) AS NodeLabel, count(n) AS Count ORDER BY Count DESC;
MATCH ()-[r]->() RETURN type(r) AS RelType, count(r) AS Count ORDER BY Count DESC;

// 2. Drugs → Concepts (RxNorm mapping)
MATCH (d:Drug)-[:NORMALIZED_TO]->(c:Concept)
RETURN d.name AS Drug, c.name AS RxNormCode
LIMIT 20;

// 3. Diagnoses → Concepts (SNOMED mapping)
MATCH (dx:Diagnosis)-[:NORMALIZED_TO]->(c:Concept)
RETURN dx.name AS Diagnosis, c.name AS SNOMEDCode
LIMIT 20;

// 4. Adverse Events → Drugs
MATCH (ae:AdverseEvent)<-[:HAS_VALUE]-(f:Field)<-[:HAS_FIELD]-(d:Dataset {name:"Drug Safety"})
MATCH (f)-[:HAS_VALUE]->(v:Drug)-[:NORMALIZED_TO]->(c:Concept)
RETURN v.name AS Drug, ae.name AS AdverseEvent, c.name AS NormalizedDrug
LIMIT 20;

// 5. Clinical Trials → Diagnoses
MATCH (d:Dataset {name:"Clinical Trials"})-[:HAS_FIELD]->(f:Field {name:"condition"})
MATCH (f)-[:HAS_VALUE]->(dx:Diagnosis)-[:NORMALIZED_TO]->(c:Concept)
RETURN dx.name AS Condition, c.name AS SNOMEDCode, count(*) AS Trials
ORDER BY Trials DESC
LIMIT 20;

// 6. Crosswalk: EHR Diagnoses ↔ Trial Conditions
MATCH (ehr:Dataset {name:"EHR"})-[:HAS_FIELD]->(f1:Field {name:"diagnosis"})
MATCH (f1)-[:HAS_VALUE]->(dx:Diagnosis)-[:NORMALIZED_TO]->(c:Concept)

MATCH (trial:Dataset {name:"Clinical Trials"})-[:HAS_FIELD]->(f2:Field {name:"condition"})
MATCH (f2)-[:HAS_VALUE]->(cond:Diagnosis)-[:NORMALIZED_TO]->(c)

RETURN dx.name AS EHR_Diagnosis, cond.name AS Trial_Condition, c.name AS ConceptCode, count(*) AS Overlap
ORDER BY Overlap DESC
LIMIT 20;

// 7. Most common fields across datasets
MATCH (d:Dataset)-[:HAS_FIELD]->(f:Field)
RETURN f.name AS FieldName, count(DISTINCT d) AS NumDatasets
ORDER BY NumDatasets DESC;

// 8. Graph of Drug → Adverse Event → Concept
MATCH (drug:Drug)-[:NORMALIZED_TO]->(c:Concept)<-[:NORMALIZED_TO]-(ae:AdverseEvent)
RETURN drug, ae, c
LIMIT 50;
