import os
import warnings

# Disable TensorFlow warnings before any imports
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
warnings.filterwarnings('ignore', category=FutureWarning)

# Try to disable TensorFlow completely
try:
    import os
    os.environ['TRANSFORMERS_OFFLINE'] = '0'
    os.environ['HF_DATASETS_OFFLINE'] = '0'
    
    # Try to prevent TensorFlow from loading
    import sys
    sys.modules['tensorflow'] = None
except:
    pass

import pandas as pd
import torch
from transformers import AutoTokenizer, AutoModel
from sklearn.metrics.pairwise import cosine_similarity
import sys
import time

# =========================
# Load BioBERT Model (PyTorch only)
# =========================
print("Loading BioBERT model (PyTorch only)...")
MODEL_NAME = "dmis-lab/biobert-base-cased-v1.1"

# Check if CUDA is available and use it
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Using device: {device}")

try:
    print("Loading tokenizer...")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, trust_remote_code=True)
    print("Loading model...")
    # Explicitly specify PyTorch framework
    model = AutoModel.from_pretrained(MODEL_NAME, trust_remote_code=True)
    
    # Move model to device
    model = model.to(device)
    model.eval()
    
    print("BioBERT model loaded successfully!")
except Exception as e:
    print(f"Error loading BioBERT model: {e}")
    print("Please make sure you have an internet connection and have installed all required packages:")
    print("pip install torch transformers scikit-learn pandas")
    sys.exit(1)

def get_embedding(text):
    """Generate BioBERT embedding for text"""
    try:
        # Tokenize and move to device
        inputs = tokenizer(text, return_tensors="pt", truncation=True, max_length=50, padding=True)
        inputs = {k: v.to(device) for k, v in inputs.items()}
        
        with torch.no_grad():
            outputs = model(**inputs)
        # Mean pooling of last hidden state
        embedding = outputs.last_hidden_state.mean(dim=1).cpu().numpy()
        return embedding
    except Exception as e:
        print(f"Error generating embedding for text '{text}': {e}")
        return None

# =========================
# Example Ontology Dictionary with Context
# =========================
ontology_terms = {
    "Hypertension": ("38341003", "SNOMED CT"),
    "Diabetes Mellitus": ("44054006", "SNOMED CT"),
    "Common Cold": ("82272006", "SNOMED CT"),
    "Cold Temperature": ("C0009264", "UMLS"),
    "Metformin": ("860975", "RxNorm"),
    "Insulin": ("28518", "RxNorm"),
    "Atorvastatin": ("83367", "RxNorm")
}

print("Generating embeddings for ontology terms...")
ontology_embeddings = {}
for i, term in enumerate(ontology_terms.keys()):
    print(f"  Processing {i+1}/{len(ontology_terms)}: {term}")
    embedding = get_embedding(term)
    if embedding is not None:
        ontology_embeddings[term] = embedding
    else:
        print(f"    Warning: Failed to generate embedding for '{term}'")

print(f"Generated embeddings for {len(ontology_embeddings)}/{len(ontology_terms)} ontology terms.")

def disambiguate_entity(term, context=""):
    """Resolve ambiguous term by comparing with ontology embeddings"""
    if not ontology_embeddings:
        print("Error: No ontology embeddings available.")
        return None, None, None
    
    try:
        candidate_text = term + " " + context if context else term
        candidate_embedding = get_embedding(candidate_text)
        
        if candidate_embedding is None:
            return None, None, None
            
        similarities = {}
        for k, v in ontology_embeddings.items():
            try:
                sim = cosine_similarity(candidate_embedding, v)[0][0]
                similarities[k] = sim
            except Exception as e:
                print(f"Error computing similarity for {k}: {e}")
                continue
        
        if not similarities:
            print("Error: No similarities computed.")
            return None, None, None
            
        best_match = max(similarities, key=similarities.get)
        return best_match, ontology_terms[best_match][0], ontology_terms[best_match][1]
    except Exception as e:
        print(f"Error in disambiguate_entity: {e}")
        return None, None, None

# =========================
# Example Usage
# =========================
if __name__ == "__main__":
    examples = [
        ("cold", "Patient presented with fever and runny nose"),
        ("cold", "Patient exposed to cold weather conditions"),
        ("Metformin", "Diabetic patient prescribed Metformin"),
    ]
    
    print("\nRunning disambiguation examples:")
    print("="*80)
    
    for term, ctx in examples:
        print(f"Input: {term} | Context: {ctx}")
        match, code, source = disambiguate_entity(term, ctx)
        if match:
            print(f"→ Disambiguated as: {match} | Code: {code} | Source: {source}")
        else:
            print("→ Disambiguation failed")
        print("-"*80)