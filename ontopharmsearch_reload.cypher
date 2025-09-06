//////////////////////////////////////////////////////////////////////////
// OntoPharmSearch Reload Script (with APOC)
// 1. Clears DB
// 2. Loads all nodes (forces IDs, properties, synonyms)
// 3. Loads all relationships
//////////////////////////////////////////////////////////////////////////

// === Step 1: Clear existing graph ===
MATCH (n) DETACH DELETE n;

//////////////////////////////////////////////////////////////////////////
// Step 2: Load all nodes
//////////////////////////////////////////////////////////////////////////
LOAD CSV WITH HEADERS FROM 'file:///ontopharmsearch_nodes_clean.csv' AS row
CALL apoc.create.node([row.label], {id: row.id, name: row.name}) YIELD node
SET node.id = row.id,
    node.prefLabel = row.prefLabel,
    node.ontology  = row.ontology,
    node.uri       = row.uri,
    node.synonyms  = CASE 
                        WHEN row.synonyms IS NULL OR row.synonyms = "" 
                        THEN [] 
                        ELSE split(row.synonyms, "|") 
                     END;

//////////////////////////////////////////////////////////////////////////
// Step 3: Load relationships
//////////////////////////////////////////////////////////////////////////
LOAD CSV WITH HEADERS FROM 'file:///ontopharmsearch_edges_clean.csv' AS row
MATCH (a {id: row.source}), (b {id: row.target})
CALL apoc.create.relationship(a, row.relation, {}, b) YIELD rel
RETURN count(rel);
