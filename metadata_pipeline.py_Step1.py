import pandas as pd

# =========================
# STEP 1: Define Dublin Core Mappings
# =========================
mappings = {
    "EHR": {
        "patient_id": "identifier",
        "diagnosis": "subject",
        "treatment": "description",
        "visit_date": "date",
        "outcome": "coverage"
    },
    "Clinical Trials": {
        "trial_id": "identifier",
        "title": "title",
        "condition": "subject",
        "intervention": "description",
        "phase": "type",
        "status": "relation",
        "start_date": "date",
        "end_date": "date",
        "location": "coverage",
        "sponsor": "contributor"
    },
    "Drug Safety": {
        "report_id": "identifier",
        "drug_name": "title",
        "adverse_event": "subject",
        "serious": "type",
        "outcome": "coverage",
        "report_date": "date",
        "country": "coverage",
        "source": "creator"
    },
    "Drug Ontology": {
        "drug_id": "identifier",
        "drug_name": "title",
        "generic_name": "subject",
        "drug_class": "type",
        "mechanism_of_action": "description",
        "route_of_administration": "format",
        "atc_code": "identifier",
        "approved": "rights",
        "synonyms": "relation"
    }
}

# =========================
# STEP 2: Concept Normalization (simple dictionary for demo)
# =========================
normalization_dict = {
    "Hypertension": ("38341003", "SNOMED CT"),
    "Diabetes": ("44054006", "SNOMED CT"),
    "Metformin": ("860975", "RxNorm"),
    "Insulin": ("28518", "RxNorm"),
    "Atorvastatin": ("83367", "RxNorm"),
    "Asthma": ("195967001", "SNOMED CT"),
    "Cancer": ("363346000", "SNOMED CT")
}

def normalize_term(term):
    if term in normalization_dict:
        return normalization_dict[term][0], normalization_dict[term][1]
    return None, None

# =========================
# STEP 3: Process Dataset
# =========================
def process_dataset(file_path, dataset_name, mappings):
    df = pd.read_csv(file_path)
    catalog_entries = []

    for col in df.columns:
        if col in mappings:
            dc_field = mappings[col]
            for val in df[col].dropna().unique()[:50]:  # sample unique values
                norm_id, source = normalize_term(str(val))
                catalog_entries.append({
                    "dataset": dataset_name,
                    "original_field": col,
                    "dublin_core_field": dc_field,
                    "sample_value": val,
                    "normalized_concept": norm_id if norm_id else "",
                    "ontology_source": source if source else ""
                })
    return catalog_entries

# =========================
# STEP 4: Run Pipeline on All Datasets
# =========================
files = {
    "EHR": "/Users/sandeepdiddi/Documents/Phd-Assistance/Sandeep_code_project_phd_final/Datasets/synthetic_ehr_50k.csv",
    "Clinical Trials": "/Users/sandeepdiddi/Documents/Phd-Assistance/Sandeep_code_project_phd_final/Datasets/clinical_trials_50k.csv",
    "Drug Safety": "/Users/sandeepdiddi/Documents/Phd-Assistance/Sandeep_code_project_phd_final/Datasets/drug_safety_50k.csv",
    "Drug Ontology": "/Users/sandeepdiddi/Documents/Phd-Assistance/Sandeep_code_project_phd_final/Datasets/drug_ontology_50k.csv"
}

all_entries = []
for dataset, file_path in files.items():
    entries = process_dataset(file_path, dataset, mappings[dataset])
    all_entries.extend(entries)

# =========================
# STEP 5: Save Metadata Catalog
# =========================
catalog_df = pd.DataFrame(all_entries)
catalog_df.to_csv("metadata_catalog.csv", index=False)

print("✅ Metadata catalog generated: metadata_catalog.csv")
