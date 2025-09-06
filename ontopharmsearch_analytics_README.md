# OntoPharmSearch Analytics Queries – Explained in Simple Terms

This README explains the Cypher queries in plain English, with easy examples.

---

### 1. Count nodes and relationships
- **What it does:** Counts how many "things" (nodes) and "connections" (relationships) exist in the graph.
- **Why:** Helps check if the data loaded properly.
- **Example:** Like counting how many people are in a party and how many conversations are happening between them.

---

### 2. Drugs → Concepts (RxNorm mapping)
- **What it does:** Finds drugs and shows their standardized RxNorm codes.
- **Why:** Different datasets may call the same drug differently. RxNorm gives a standard reference.
- **Example:** "Metformin" → RxNorm code 860975. Think of it like mapping "John" → Aadhaar number.

---

### 3. Diagnoses → Concepts (SNOMED mapping)
- **What it does:** Links diagnoses (like "Diabetes") to official SNOMED CT codes.
- **Why:** Standardization makes it easier to compare across hospitals/trials.
- **Example:** "Diabetes" → SNOMED code 44054006.

---

### 4. Adverse Events → Drugs
- **What it does:** Finds which drugs are linked to which side effects.
- **Why:** Important for drug safety analysis.
- **Example:** "Atorvastatin" → "Liver Damage".

---

### 5. Clinical Trials → Diagnoses
- **What it does:** Lists medical conditions studied in trials and their SNOMED codes.
- **Why:** Shows research focus areas.
- **Example:** Clinical Trials dataset → "Breast Cancer" → SNOMED code 254837009.

---

### 6. Crosswalk: EHR Diagnoses ↔ Trial Conditions
- **What it does:** Connects real-world patient diagnoses (EHR) to conditions studied in clinical trials.
- **Why:** Helps align real-world data with research data.
- **Example:** EHR shows "Hypertension", Clinical Trial studies "High Blood Pressure" → both map to SNOMED 38341003.

---

### 7. Most common fields across datasets
- **What it does:** Finds metadata fields used across multiple datasets.
- **Why:** Helps identify common data structures.
- **Example:** Field "diagnosis" appears in EHR and Trials, "drug_name" appears in Drug Safety and Ontology.

---

### 8. Graph of Drug → Adverse Event → Concept
- **What it does:** Visualizes path: Drug → Standard Concept → Adverse Event.
- **Why:** Shows how ontology connects drugs and side effects.
- **Example:** "Metformin" → SNOMED code 860975 → "Nausea".
