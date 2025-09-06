//////////////////////////////////////////////////////////////////////////
// Validation Queries
//////////////////////////////////////////////////////////////////////////

// 1. Count nodes by label
MATCH (n) RETURN labels(n) AS NodeLabel, count(n) AS Count ORDER BY Count DESC;

// 2. Count relationships by type
MATCH ()-[r]->() RETURN type(r) AS RelType, count(r) AS Count ORDER BY Count DESC;

// 3. Sample Concept nodes
MATCH (c:Concept) RETURN c.prefLabel, c.ontology, c.uri LIMIT 20;

// 4. Drugs → RxNorm
MATCH (d:Drug)-[:NORMALIZED_TO]->(c:Concept {ontology:"RXNORM"})
RETURN d.name, c.prefLabel, c.uri LIMIT 20;

// 5. Diagnoses → SNOMED CT
MATCH (dx:Diagnosis)-[:NORMALIZED_TO]->(c:Concept {ontology:"SNOMEDCT"})
RETURN dx.name, c.prefLabel, c.uri LIMIT 20;

// 6. Adverse Events → SNOMED CT
MATCH (ae:AdverseEvent)-[:NORMALIZED_TO]->(c:Concept {ontology:"SNOMEDCT"})
RETURN ae.name, c.prefLabel, c.uri LIMIT 20;

// 7. Clinical Trials → Diagnoses
MATCH (d:Dataset {name:"Clinical Trials"})-[:HAS_FIELD]->(f:Field {name:"condition"})
MATCH (f)-[:HAS_VALUE]->(dx:Diagnosis)-[:NORMALIZED_TO]->(c:Concept {ontology:"SNOMEDCT"})
RETURN dx.name, c.prefLabel, c.uri LIMIT 20;

// 8. EHR ↔ Trials Crosswalk
MATCH (ehr:Dataset {name:"EHR"})-[:HAS_FIELD]->(f1:Field {name:"diagnosis"})
MATCH (f1)-[:HAS_VALUE]->(dx:Diagnosis)-[:NORMALIZED_TO]->(c:Concept)
MATCH (trial:Dataset {name:"Clinical Trials"})-[:HAS_FIELD]->(f2:Field {name:"condition"})
MATCH (f2)-[:HAS_VALUE]->(cond:Diagnosis)-[:NORMALIZED_TO]->(c)
RETURN dx.name AS EHR_Diagnosis, cond.name AS Trial_Condition, c.prefLabel AS Concept LIMIT 20;

// 9. Drug ↔ Adverse Event ↔ Concept
MATCH (drug:Drug)-[:NORMALIZED_TO]->(c:Concept)<-[:NORMALIZED_TO]-(ae:AdverseEvent)
RETURN drug.name, ae.name, c.prefLabel LIMIT 20;
