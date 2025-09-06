//////////////////////////////////////////////////////////////////////////
// OntoPharmSearch Validation & Visualization Queries
// Run after reload to confirm graph structure and visualize connections
//////////////////////////////////////////////////////////////////////////

// === 1. Node counts by label ===
MATCH (n) 
RETURN labels(n) AS NodeLabel, count(n) AS Count 
ORDER BY Count DESC;

// === 2. Relationship counts by type ===
MATCH ()-[r]->() 
RETURN type(r) AS RelType, count(r) AS Count 
ORDER BY Count DESC;

// === 3. Sample Dataset → Field → Value chain ===
MATCH (d:Dataset)-[:HAS_FIELD]->(f:Field)-[:HAS_VALUE]->(v)
RETURN d,f,v
LIMIT 20;

// === 4. Drug → Concept (RxNorm) ===
MATCH (drug:Drug)-[:NORMALIZED_TO]->(c:Concept {ontology:"RXNORM"})
RETURN drug, c
LIMIT 20;

// === 5. Diagnosis → Concept (SNOMED CT) ===
MATCH (dx:Diagnosis)-[:NORMALIZED_TO]->(c:Concept {ontology:"SNOMEDCT"})
RETURN dx, c
LIMIT 20;

// === 6. AdverseEvent → Concept (SNOMED CT) ===
MATCH (ae:AdverseEvent)-[:NORMALIZED_TO]->(c:Concept {ontology:"SNOMEDCT"})
RETURN ae, c
LIMIT 20;

// === 7. Drug ↔ Concept ↔ AdverseEvent (safety signals) ===
MATCH (drug:Drug)-[:NORMALIZED_TO]->(c:Concept)<-[:NORMALIZED_TO]-(ae:AdverseEvent)
RETURN drug, ae, c
LIMIT 50;

// === 8. EHR Diagnoses ↔ Trial Conditions (crosswalk via Concept) ===
MATCH (ehr:Dataset {name:"EHR"})-[:HAS_FIELD]->(f1:Field)-[:HAS_VALUE]->(dx:Diagnosis)-[:NORMALIZED_TO]->(c:Concept)
MATCH (trial:Dataset {name:"Clinical Trials"})-[:HAS_FIELD]->(f2:Field)-[:HAS_VALUE]->(cond:Diagnosis)-[:NORMALIZED_TO]->(c)
RETURN dx, cond, c
LIMIT 50;

// === 9. Synonym expansion test (e.g., "high blood sugar") ===
MATCH (c:Concept)
WHERE "high blood sugar" IN c.synonyms
RETURN c.prefLabel, c.synonyms, c.uri;
