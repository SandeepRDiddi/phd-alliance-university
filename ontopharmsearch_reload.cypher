//////////////////////////////////////////////////////////////////////////
// OntoPharmSearch – Full Reload Script
// Clears DB, loads nodes + relationships from CSV
//////////////////////////////////////////////////////////////////////////

// === STEP 1: Clear existing graph ===
MATCH (n) DETACH DELETE n;

//////////////////////////////////////////////////////////////////////////
// === STEP 2: Load nodes (with APOC) ===
//////////////////////////////////////////////////////////////////////////
LOAD CSV WITH HEADERS FROM 'file:///ontopharmsearch_nodes_clean.csv' AS row
CALL apoc.create.node([row.label], {
  id: row.id,
  name: row.name,
  label: row.label,
  ontology: row.ontology,
  code: row.code,
  uri: row.uri,
  synonyms: CASE
              WHEN row.synonyms IS NULL OR row.synonyms = '' THEN []
              ELSE split(row.synonyms, '|')
            END
}) YIELD node
RETURN count(node);

//////////////////////////////////////////////////////////////////////////
// === STEP 3: Load relationships (with APOC) ===
//////////////////////////////////////////////////////////////////////////
LOAD CSV WITH HEADERS FROM 'file:///ontopharmsearch_edges_clean.csv' AS row
MATCH (s {id: row.source}), (t {id: row.target})
CALL apoc.create.relationship(s, row.relation, {}, t) YIELD rel
RETURN count(rel);
