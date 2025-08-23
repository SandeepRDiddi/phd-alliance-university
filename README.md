# Metadata Pipeline with Entity Disambiguation

This project processes medical datasets and performs entity disambiguation using the BioBERT model.

## Requirements

Install the required packages:
```bash
pip install -r requirements.txt
```

Or install individually:
```bash
pip install pandas torch transformers scikit-learn
```

## Project Structure

- `metadata_pipeline.py_Step1.py`: Main pipeline for generating metadata catalog from all datasets
- `metadata_pipeline_torch_only.py`: Optimized entity disambiguation using only PyTorch (recommended)
- `requirements.txt`: Required Python packages
- `Datasets/`: Contains the medical datasets
- `metadata_catalog.csv`: Generated metadata catalog
- SQL files: `load-data-db.sql`, `metadata.sql`

## Running the Pipeline

1. For basic metadata processing (generates metadata_catalog.csv):
   ```bash
   python metadata_pipeline.py_Step1.py
   ```

2. For entity disambiguation with BioBERT (recommended):
   ```bash
   python metadata_pipeline_torch_only.py
   ```

## Troubleshooting

If you encounter issues with the model download:
1. Check your internet connection
2. Ensure you have sufficient disk space (model is ~400MB)
3. Try using a different network or VPN

## TensorFlow AVX Warning

If you see the warning "The TensorFlow library was compiled to use AVX instructions, but these aren't available on your machine", use the `metadata_pipeline_torch_only.py` script which prevents TensorFlow from loading and uses only PyTorch.