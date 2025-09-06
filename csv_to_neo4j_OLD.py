import pandas as pd

def create_neo4j_graph_data():
    """Convert metadata catalog to Neo4j graph data format (nodes and edges)"""
    # Load metadata catalog
    df = pd.read_csv("metadata_catalog.csv")
    
    nodes = []
    edges = []
    
    for i, row in df.iterrows():
        dataset_id = f"dataset_{i}"
        field_id = f"field_{i}"
        dcfield_id = f"dcfield_{i}"
        value_id = f"value_{i}"
        concept_id = f"concept_{i}" if pd.notna(row["normalized_concept"]) else None
        
        # Dataset node
        nodes.append([dataset_id, row["dataset"], "Dataset"])
        
        # Field node
        nodes.append([field_id, row["original_field"], "Field"])
        
        # Dublin Core field node
        nodes.append([dcfield_id, row["dublin_core_field"], "DublinCore"])
        
        # Value node
        if pd.notna(row["sample_value"]):
            nodes.append([value_id, str(row["sample_value"]), "Value"])
        
        # Concept node
        if concept_id:
            nodes.append([concept_id, str(row["normalized_concept"]), "Concept"])
        
        # Edges
        edges.append([dataset_id, field_id, "HAS_FIELD"])
        edges.append([field_id, dcfield_id, "MAPPED_TO"])
        if pd.notna(row["sample_value"]):
            edges.append([field_id, value_id, "HAS_VALUE"])
        if concept_id:
            edges.append([value_id, concept_id, "NORMALIZED_TO"])
    
    # Deduplicate nodes
    nodes_df = pd.DataFrame(nodes, columns=["id","name","type"]).drop_duplicates()
    edges_df = pd.DataFrame(edges, columns=["source","target","relation"]).drop_duplicates()
    
    # Save CSVs
    nodes_df.to_csv("ontopharmsearch_nodes.csv", index=False)
    edges_df.to_csv("ontopharmsearch_edges.csv", index=False)
    
    print("✅ Exported ontopharmsearch_nodes.csv and ontopharmsearch_edges.csv for Neo4j")

if __name__ == "__main__":
    create_neo4j_graph_data()
