#!/usr/bin/env python3
"""
Script to convert metadata_catalog.csv to RDF (Turtle) for Fuseki.
"""

import csv
import os
from datetime import datetime

def write_turtle_header(file):
    """Write the Turtle header with namespace declarations."""
    file.write("@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n")
    file.write("@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n")
    file.write("@prefix dcterms: <http://purl.org/dc/terms/> .\n")
    file.write("@prefix skos: <http://www.w3.org/2004/02/skos/core#> .\n")
    file.write("@prefix schema: <http://schema.org/> .\n")
    file.write("@prefix obo: <http://purl.obolibrary.org/obo/> .\n")
    file.write("@prefix snomed: <http://snomed.info/id/> .\n")
    file.write("@prefix rxnorm: <http://purl.bioontology.org/ontology/RXNORM/> .\n")
    file.write("@prefix catalog: <https://phd-alliance-university.edu/catalog#> .\n")
    file.write("@prefix dataset: <https://phd-alliance-university.edu/dataset/> .\n")
    file.write("@prefix concept: <https://phd-alliance-university.edu/concept/> .\n")
    file.write("@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n\n")

def get_ontology_uri(ontology_source, normalized_concept):
    """Get the URI for an ontology concept."""
    if not ontology_source or not normalized_concept:
        return None
    
    if ontology_source == 'SNOMED CT':
        return f"snomed:{normalized_concept}"
    elif ontology_source == 'RxNorm':
        return f"rxnorm:{normalized_concept}"
    return None

def escape_literal(value):
    """Escape special characters for Turtle literals."""
    return value.replace('"', '\\"')

def convert_csv_to_rdf(input_file, output_file):
    with open(input_file, 'r', newline='', encoding='utf-8') as csvfile, \
         open(output_file, 'w', encoding='utf-8') as turtlefile:
        
        write_turtle_header(turtlefile)
        reader = csv.DictReader(csvfile)

        for row_num, row in enumerate(reader, start=2):  
            entry_id = f"entry_{row_num:04d}"
            
            dataset = escape_literal(row['dataset'])
            original_field = escape_literal(row['original_field'])
            dublin_core_field = escape_literal(row['dublin_core_field'])
            sample_value = escape_literal(str(row['sample_value']))
            normalized_concept = row['normalized_concept']
            ontology_source = row['ontology_source']

            turtlefile.write(f"dataset:{entry_id} a catalog:MetadataEntry ;\n")
            turtlefile.write(f"    catalog:datasetType \"{dataset}\" ;\n")
            turtlefile.write(f"    catalog:originalField \"{original_field}\" ;\n")
            turtlefile.write(f"    catalog:dublinCoreField \"{dublin_core_field}\" ;\n")

            if sample_value and sample_value != "nan":
                try:
                    datetime.strptime(sample_value, '%Y-%m-%d')
                    turtlefile.write(f"    catalog:sampleValue \"{sample_value}\"^^xsd:date ;\n")
                except ValueError:
                    turtlefile.write(f"    catalog:sampleValue \"{sample_value}\" ;\n")
            
            if normalized_concept and normalized_concept != "nan":
                turtlefile.write(f"    catalog:normalizedConcept \"{normalized_concept}\" ;\n")
                ontology_uri = get_ontology_uri(ontology_source, normalized_concept)
                if ontology_uri:
                    turtlefile.write(f"    catalog:ontologySource {ontology_uri} ;\n")

            if ontology_source and ontology_source != "nan":
                turtlefile.write(f"    catalog:ontologySourceName \"{ontology_source}\" ;\n")

            turtlefile.write("    .\n\n")

def main():
    input_file = "metadata_catalog.csv"
    output_file = "metadata_catalog.ttl"
    
    if not os.path.exists(input_file):
        print(f"Error: Input file '{input_file}' not found.")
        return
    
    convert_csv_to_rdf(input_file, output_file)
    print(f"✅ Successfully converted '{input_file}' → '{output_file}'")

if __name__ == "__main__":
    main()
