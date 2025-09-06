//////////////////////////////////////////////////////////////////////////
// OntoPharmSearch Import Script (with APOC, fixed IDs)
//////////////////////////////////////////////////////////////////////////

// === Non-Concept nodes ===
LOAD CSV WITH HEADERS FROM 'file:///ontopharmsearch_nodes_clean.csv' AS row
WITH row WHERE row.label <> "Concept"
CALL apoc.create.node([row.label], {id: row.id, name: row.name}) YIELD node
SET node.id = row.id   // 🔹 force ID to exist
RETURN count(node);

// === Concept nodes ===
LOAD CSV WITH HEADERS FROM 'file:///ontopharmsearch_nodes_clean.csv' AS row
WITH row WHERE row.label = "Concept"
MERGE (n:Concept {id: row.id})
SET n.prefLabel = row.prefLabel,
    n.ontology  = row.ontology,
    n.uri       = row.uri,
    n.synonyms  = CASE 
                     WHEN row.synonyms IS NULL OR row.synonyms = "" 
                     THEN [] 
                     ELSE split(row.synonyms, "|") 
                  END;

// === Relationships ===
LOAD CSV WITH HEADERS FROM 'file:///ontopharmsearch_edges_clean.csv' AS row
MATCH (a {id: row.source}), (b {id: row.target})
CALL apoc.create.relationship(a, row.relation, {}, b) YIELD rel
RETURN count(rel);
