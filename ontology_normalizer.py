#!/usr/bin/env python3
"""
Ontology Normalizer for OntoPharmSearch
---------------------------------------
Now includes synonyms from BioPortal.
1. Try exact match first.
2. Apply rule-based disambiguation.
3. Store prefLabel, ontology, uri, synonyms.
"""

import requests
import os

BIOPORTAL_API_KEY = os.getenv("BIOPORTAL_API_KEY", "your_api_key_here")
BIOPORTAL_BASE_URL = "https://data.bioontology.org"


def normalize_term(term, ontology="SNOMEDCT"):
    if not term:
        return None, None, ontology, []

    headers = {
        "Authorization": f"apikey token={BIOPORTAL_API_KEY}",
        "Accept": "application/json"
    }

    # Step 1: Try exact match
    url_exact = f"{BIOPORTAL_BASE_URL}/search?q={term}&ontologies={ontology}&require_exact_match=true"
    r = requests.get(url_exact, headers=headers, timeout=10)
    if r.status_code == 200:
        results = r.json().get("collection", [])
        if results:
            res = results[0]
            synonyms = res.get("synonym", [])
            return res["@id"], res.get("prefLabel", term), ontology, synonyms

    # Step 2: Fallback search
    url_fallback = f"{BIOPORTAL_BASE_URL}/search?q={term}&ontologies={ontology}"
    r = requests.get(url_fallback, headers=headers, timeout=10)
    if r.status_code != 200:
        return None, None, ontology, []

    results = r.json().get("collection", [])
    if not results:
        return None, None, ontology, []

    term_lower = term.lower()

    for res in results:
        label = res.get("prefLabel", "").lower()
        synonyms = res.get("synonym", [])

        # Diabetes → Diabetes mellitus
        if "diabetes" in term_lower and "mellitus" in label:
            return res["@id"], res.get("prefLabel"), ontology, synonyms

        # Generic drug preference
        if ontology == "RXNORM":
            if label == term_lower:
                return res["@id"], res.get("prefLabel"), ontology, synonyms
            if term_lower in label and "injection" not in label and "tablet" not in label:
                return res["@id"], res.get("prefLabel"), ontology, synonyms

        # Prefer disease concepts in SNOMED
        if ontology == "SNOMEDCT":
            if "disorder" in label or "disease" in label or "syndrome" in label:
                return res["@id"], res.get("prefLabel"), ontology, synonyms

    # Step 3: Fallback to first candidate
    res = results[0]
    synonyms = res.get("synonym", [])
    return res["@id"], res.get("prefLabel", term), ontology, synonyms


# === Example usage ===
if __name__ == "__main__":
    examples = [
        ("Diabetes", "SNOMEDCT"),
        ("Hypertension", "SNOMEDCT"),
        ("Asthma", "SNOMEDCT"),
        ("Metformin", "RXNORM"),
        ("Insulin", "RXNORM"),
        ("Nausea", "SNOMEDCT"),
    ]

    for term, ont in examples:
        cid, label, source, syns = normalize_term(term, ont)
        print(f"{term} → {label} ({source}) [{cid}]")
        if syns:
            print(f"   Synonyms: {', '.join(syns[:5])}")  # show first 5
