import pandas as pd
from ontology_normalizer import normalize_term  # returns (uri, prefLabel, ontology, synonyms)

# Fallbacks if BioPortal returns nothing (guarantees NORMALIZED_TO edges)
FALLBACK = {
    "diabetes": ("http://purl.bioontology.org/ontology/SNOMEDCT/44054006", "Diabetes mellitus", "SNOMEDCT", ["high blood sugar","sugar diabetes","dm"]),
    "hypertension": ("http://purl.bioontology.org/ontology/SNOMEDCT/38341003", "Hypertensive disorder", "SNOMEDCT", ["high blood pressure","htn"]),
    "asthma": ("http://purl.bioontology.org/ontology/SNOMEDCT/195967001", "Asthma", "SNOMEDCT", ["bronchial asthma"]),
    "nausea": ("http://purl.bioontology.org/ontology/SNOMEDCT/422587007", "Nausea", "SNOMEDCT", ["queasiness"]),
    "metformin": ("http://purl.bioontology.org/ontology/RXNORM/6809", "metformin", "RXNORM", []),
    "insulin": ("http://purl.bioontology.org/ontology/RXNORM/28518", "Insulin", "RXNORM", []),
    "atorvastatin": ("http://purl.bioontology.org/ontology/RXNORM/83367", "Atorvastatin", "RXNORM", [])
}

df = pd.read_csv("metadata_catalog.csv")

nodes, edges = [], []

for i, row in df.iterrows():
    dataset_id = f"dataset_{i}"
    field_id   = f"field_{i}"
    dcfield_id = f"dcfield_{i}"
    value_id   = f"value_{i}"

    # Nodes: Dataset / Field / DublinCore
    nodes.append([dataset_id, "Dataset",   row["dataset"],            None, None, None, None])
    nodes.append([field_id,   "Field",     row["original_field"],     None, None, None, None])
    nodes.append([dcfield_id, "DublinCore",row["dublin_core_field"],  None, None, None, None])

    # Value node + classification
    if pd.notna(row["sample_value"]):
        val = str(row["sample_value"]).strip()
        f   = str(row["original_field"]).strip().lower()

        label = "Value"
        if f in ["treatment","drug_name"]:
            label = "Drug"
        elif f in ["diagnosis","condition"]:
            label = "Diagnosis"
        elif f in ["adverse_event"]:
            label = "AdverseEvent"

        nodes.append([value_id, label, val, None, None, None, None])

        # Build list of (uri, prefLabel, ontology, synonyms[]) concepts to attach
        concepts = []

        # Drugs → map to BOTH RxNorm and SNOMEDCT (to enable cross-ontology joins)
        if label == "Drug":
            for ont in ["RXNORM", "SNOMEDCT"]:
                uri, pref, src, syns = normalize_term(val, ont)
                if uri:
                    concepts.append((uri, pref, src, [s.lower() for s in (syns or [])]))
            # fallback at least to RxNorm if nothing
            if not concepts:
                key = val.lower()
                if key in FALLBACK:
                    uri, pref, src, syns = FALLBACK[key]
                    concepts.append((uri, pref, src, [s.lower() for s in syns]))

        # Diagnoses / Conditions / Adverse Events → SNOMEDCT
        elif label in ["Diagnosis","AdverseEvent"]:
            uri, pref, src, syns = normalize_term(val, "SNOMEDCT")
            if uri:
                concepts.append((uri, pref, src, [s.lower() for s in (syns or [])]))
            elif val.lower() in FALLBACK:
                uri, pref, src, syns = FALLBACK[val.lower()]
                concepts.append((uri, pref, src, [s.lower() for s in syns]))

        # Create Concept nodes + NORMALIZED_TO edges
        for j, (uri, pref, src, syns) in enumerate(concepts):
            concept_id = f"concept_{i}_{j}"
            code = uri.rsplit("/", 1)[-1] if "/" in uri else uri
            nodes.append([concept_id, "Concept", pref, src, code, uri, "|".join(syns)])
            edges.append([value_id, concept_id, "NORMALIZED_TO"])

    # Structural edges
    edges.append([dataset_id, field_id,  "HAS_FIELD"])
    edges.append([field_id,   dcfield_id,"MAPPED_TO"])
    if pd.notna(row["sample_value"]):
        edges.append([field_id, value_id, "HAS_VALUE"])

# Dedup & save
nodes_df = pd.DataFrame(nodes, columns=["id","label","name","ontology","code","uri","synonyms"]).drop_duplicates()
edges_df = pd.DataFrame(edges, columns=["source","target","relation"]).drop_duplicates()

nodes_df.to_csv("ontopharmsearch_nodes_clean.csv", index=False)
edges_df.to_csv("ontopharmsearch_edges_clean.csv", index=False)

print("✅ Wrote ontopharmsearch_nodes_clean.csv (with synonyms) and ontopharmsearch_edges_clean.csv (incl. NORMALIZED_TO)")
