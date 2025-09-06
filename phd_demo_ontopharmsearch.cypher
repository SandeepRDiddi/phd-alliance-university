//////////////////////////////////////////////////////////////////////////
// OntoPharmSearch – PhD Demo Script
// This script seeds a mini knowledge graph and shows queries step by step
//////////////////////////////////////////////////////////////////////////

// STEP 0: Clean up any old demo nodes
MATCH (n)
WHERE n.id STARTS WITH 'demo_'
DETACH DELETE n;

//////////////////////////////////////////////////////////////////////////
// STEP 1: Create demo nodes
//////////////////////////////////////////////////////////////////////////

// Create a drug (Metformin)
MERGE (drug:Drug {id:'demo_drug_metformin', name:'Metformin'})

// Create an adverse event (Nausea)
MERGE (ae:AdverseEvent {id:'demo_ae_nausea', name:'Nausea'})

// Create ontology concepts
MERGE (c_rx:Concept {id:'demo_c_rxnorm_6809'})
  ON CREATE SET c_rx.prefLabel='metformin',
                c_rx.ontology='RXNORM',
                c_rx.code='6809',
                c_rx.uri='http://purl.bioontology.org/ontology/RXNORM/6809',
                c_rx.synonyms=['metformin']

MERGE (c_sno_drug:Concept {id:'demo_c_snomed_860975'})
  ON CREATE SET c_sno_drug.prefLabel='Metformin',
                c_sno_drug.ontology='SNOMEDCT',
                c_sno_drug.code='860975',
                c_sno_drug.uri='http://purl.bioontology.org/ontology/SNOMEDCT/860975',
                c_sno_drug.synonyms=['metformin']

MERGE (c_sno_ae:Concept {id:'demo_c_snomed_422587007'})
  ON CREATE SET c_sno_ae.prefLabel='Nausea',
                c_sno_ae.ontology='SNOMEDCT',
                c_sno_ae.code='422587007',
                c_sno_ae.uri='http://purl.bioontology.org/ontology/SNOMEDCT/422587007',
                c_sno_ae.synonyms=['nausea','queasiness']

//////////////////////////////////////////////////////////////////////////
// STEP 2: Connect drug + AE to ontology concepts
//////////////////////////////////////////////////////////////////////////

MERGE (drug)-[:NORMALIZED_TO]->(c_rx)
MERGE (drug)-[:NORMALIZED_TO]->(c_sno_drug)
MERGE (ae)-[:NORMALIZED_TO]->(c_sno_ae)

// Pharmacovigilance safety link
MERGE (c_sno_drug)-[:MAY_CAUSE]->(c_sno_ae)

//////////////////////////////////////////////////////////////////////////
// STEP 3: Demo Queries
//////////////////////////////////////////////////////////////////////////

// === Query A: Basic demo (Drug ↔ Concept ↔ Adverse Event) ===
// EXPLAIN: This shows Metformin and Nausea linked through a shared concept.
MATCH (drug:Drug)-[:NORMALIZED_TO]->(c:Concept)<-[:NORMALIZED_TO]-(ae:AdverseEvent)
RETURN drug, ae, c
LIMIT 20;

// === Query B: Safety relation with MAY_CAUSE ===
// EXPLAIN: The correct biomedical pattern – Metformin concept MAY_CAUSE Nausea concept.
MATCH (drug:Drug)-[:NORMALIZED_TO]->(cDrug:Concept {ontology:'SNOMEDCT'})
MATCH (cDrug)-[:MAY_CAUSE]->(cAE:Concept {ontology:'SNOMEDCT'})
MATCH (ae:AdverseEvent)-[:NORMALIZED_TO]->(cAE)
RETURN drug, cDrug, ae, cAE
LIMIT 20;

// === Query C: Synonym expansion ===
// EXPLAIN: Even if the doctor wrote "high blood sugar", we still match Diabetes mellitus.
MATCH (c:Concept)
WHERE "high blood sugar" IN c.synonyms
RETURN c.prefLabel, c.synonyms, c.uri;

// === Query D: Node & relationship counts ===
// EXPLAIN: A quick check of how structured the graph is.
MATCH (n) RETURN labels(n) AS NodeLabel, count(n) AS Count ORDER BY Count DESC;
MATCH ()-[r]->() RETURN type(r) AS RelType, count(r) AS Count ORDER BY Count DESC;
