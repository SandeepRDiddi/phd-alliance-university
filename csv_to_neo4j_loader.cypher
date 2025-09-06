//////////////////////////////////////////////////////////////////////////
// Clean reload
//////////////////////////////////////////////////////////////////////////
MATCH (n) DETACH DELETE n;

//////////////////////////////////////////////////////////////////////////
// Load nodes (non-Concept): dynamic labels via APOC
//////////////////////////////////////////////////////////////////////////
LOAD CSV WITH HEADERS FROM 'file:///ontopharmsearch_nodes_clean.csv' AS row
WITH row WHERE row.label <> 'Concept'
CALL apoc.create.node([row.label], {
  id: row.id,
  name: row.name,
  label: row.label,
  ontology: row.ontology,
  code: row.code,
  uri: row.uri
}) YIELD node
RETURN count(node);

//////////////////////////////////////////////////////////////////////////
// Load Concept nodes with synonyms array
//////////////////////////////////////////////////////////////////////////
LOAD CSV WITH HEADERS FROM 'file:///ontopharmsearch_nodes_clean.csv' AS row
WITH row WHERE row.label = 'Concept'
CALL apoc.create.node(['Concept'], {
  id: row.id,
  name: row.name,
  label: row.label,
  ontology: row.ontology,
  code: row.code,
  uri: row.uri
}) YIELD node
WITH node, row
SET node.synonyms = CASE
  WHEN row.synonyms IS NULL OR row.synonyms = '' THEN []
  ELSE [s IN split(row.synonyms,'|') WHERE s <> '']
END
RETURN count(node);

//////////////////////////////////////////////////////////////////////////
// Load relationships (true types)
//////////////////////////////////////////////////////////////////////////
LOAD CSV WITH HEADERS FROM 'file:///ontopharmsearch_edges_clean.csv' AS row
MATCH (s {id: row.source}), (t {id: row.target})
CALL apoc.create.relationship(s, row.relation, {}, t) YIELD rel
RETURN count(rel);
