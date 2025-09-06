#!/usr/bin/env python3
"""
Script to run SPARQL queries against the RDF data.
"""

import rdflib
from rdflib import Graph, Namespace
from rdflib.namespace import RDF, RDFS, XSD

# Define namespaces
CATALOG = Namespace("https://phd-alliance-university.edu/catalog#")
DATASET = Namespace("https://phd-alliance-university.edu/dataset/")
SNOMED = Namespace("http://snomed.info/id/")
RXNORM = Namespace("http://purl.bioontology.org/ontology/RXNORM/")

def load_rdf_data(rdf_file):
    """Load RDF data from a Turtle file."""
    g = Graph()
    g.parse(rdf_file, format='turtle')
    print(f"Loaded {len(g)} triples from {rdf_file}")
    return g

def execute_queries(graph):
    """Execute SPARQL queries against the RDF graph."""
    
    # Query 1: List all triples (sanity check)
    print("\n--- 1. List all triples (sanity check) ---")
    q1 = """
    SELECT ?s ?p ?o 
    WHERE { ?s ?p ?o }
    LIMIT 20
    """
    try:
        results = graph.query(q1)
        for row in results:
            print(row)
    except Exception as e:
        print(f"Error executing query 1: {e}")
    
    # Query 2: Find all datasets represented
    print("\n--- 2. Find all datasets represented ---")
    q2 = """
    SELECT DISTINCT ?dataset
    WHERE {
      ?entry <https://phd-alliance-university.edu/catalog#datasetType> ?dataset .
    }
    """
    try:
        results = graph.query(q2)
        for row in results:
            print(row)
    except Exception as e:
        print(f"Error executing query 2: {e}")
    
    # Query 3: Get all fields mapped to Dublin Core
    print("\n--- 3. Get all fields mapped to Dublin Core ---")
    q3 = """
    SELECT DISTINCT ?original ?dcField
    WHERE {
      ?entry <https://phd-alliance-university.edu/catalog#originalField> ?original ;
             <https://phd-alliance-university.edu/catalog#dublinCoreField> ?dcField .
    }
    LIMIT 50
    """
    try:
        results = graph.query(q3)
        for row in results:
            print(row)
    except Exception as e:
        print(f"Error executing query 3: {e}")
    
    # Query 4: Retrieve all concepts normalized to SNOMED CT
    print("\n--- 4. Retrieve all concepts normalized to SNOMED CT ---")
    q4 = """
    SELECT ?entry ?value ?concept
    WHERE {
      ?entry <https://phd-alliance-university.edu/catalog#sampleValue> ?value ;
             <https://phd-alliance-university.edu/catalog#ontologySourceName> "SNOMED CT" ;
             <https://phd-alliance-university.edu/catalog#normalizedConcept> ?concept .
    }
    LIMIT 20
    """
    try:
        results = graph.query(q4)
        for row in results:
            print(row)
    except Exception as e:
        print(f"Error executing query 4: {e}")
    
    # Query 5: Find all drugs linked to RxNorm
    print("\n--- 5. Find all drugs linked to RxNorm ---")
    q5 = """
    SELECT ?entry ?drug ?rx
    WHERE {
      ?entry <https://phd-alliance-university.edu/catalog#sampleValue> ?drug ;
             <https://phd-alliance-university.edu/catalog#ontologySourceName> "RxNorm" ;
             <https://phd-alliance-university.edu/catalog#ontologySource> ?rx .
    }
    LIMIT 20
    """
    try:
        results = graph.query(q5)
        for row in results:
            print(row)
    except Exception as e:
        print(f"Error executing query 5: {e}")
    
    # Query 6: Query EHR diagnoses (subject field)
    print("\n--- 6. Query EHR diagnoses (subject field) ---")
    q6 = """
    SELECT ?patient ?diagnosis ?concept
    WHERE {
      ?entry <https://phd-alliance-university.edu/catalog#datasetType> "EHR" ;
             <https://phd-alliance-university.edu/catalog#originalField> "diagnosis" ;
             <https://phd-alliance-university.edu/catalog#sampleValue> ?diagnosis ;
             <https://phd-alliance-university.edu/catalog#normalizedConcept> ?concept .
      BIND(REPLACE(STR(?entry), "^.*entry_", "Patient_") AS ?patient)
    }
    LIMIT 20
    """
    try:
        results = graph.query(q6)
        for row in results:
            print(row)
    except Exception as e:
        print(f"Error executing query 6: {e}")
    
    # Query 7: Find potential adverse events for a given drug
    print("\n--- 7. Find potential adverse events for a given drug ---")
    q7 = """
    SELECT ?drug ?adverseEvent ?concept
    WHERE {
      ?entry <https://phd-alliance-university.edu/catalog#datasetType> "Drug Safety" ;
             <https://phd-alliance-university.edu/catalog#originalField> "adverse_event" ;
             <https://phd-alliance-university.edu/catalog#sampleValue> ?adverseEvent ;
             <https://phd-alliance-university.edu/catalog#normalizedConcept> ?concept .
      OPTIONAL { ?entry <https://phd-alliance-university.edu/catalog#ontologySourceName> ?drugOntology }
      BIND("Atorvastatin" AS ?drug)
    }
    LIMIT 20
    """
    try:
        results = graph.query(q7)
        for row in results:
            print(row)
    except Exception as e:
        print(f"Error executing query 7: {e}")
    
    # Query 8: Crosswalk: Clinical trial conditions → SNOMED
    print("\n--- 8. Crosswalk: Clinical trial conditions → SNOMED ---")
    q8 = """
    SELECT ?trial ?condition ?concept
    WHERE {
      ?entry <https://phd-alliance-university.edu/catalog#datasetType> "Clinical Trials" ;
             <https://phd-alliance-university.edu/catalog#originalField> "condition" ;
             <https://phd-alliance-university.edu/catalog#sampleValue> ?condition ;
             <https://phd-alliance-university.edu/catalog#normalizedConcept> ?concept .
      BIND(REPLACE(STR(?entry), "^.*entry_", "Trial_") AS ?trial)
    }
    LIMIT 20
    """
    try:
        results = graph.query(q8)
        for row in results:
            print(row)
    except Exception as e:
        print(f"Error executing query 8: {e}")

def main():
    # Load RDF data
    rdf_file = "metadata_catalog.ttl"
    graph = load_rdf_data(rdf_file)
    
    # Execute queries
    execute_queries(graph)

if __name__ == "__main__":
    main()