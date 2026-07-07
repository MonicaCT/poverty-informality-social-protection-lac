# Reproducibility Guide

The public workflow starts from the processed panel committed under `data/processed/`. This makes the dashboard testable on a clean computer without private raw archives.

## Setup

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

## Public Rebuild

```bash
python code/python/02_descriptive_analysis.py
python code/python/03_build_dashboard.py
python tests/test_panel_integrity.py
python tests/test_repository_outputs.py
python tests/test_publication_readiness.py
```

## Full Raw Rebuild

The raw rebuild requires local data archives configured in `config/project_sources.yml`:

```bash
./run_pipeline.sh --full-raw-rebuild
```

Windows:

```powershell
./run_pipeline.ps1 -FullRawRebuild
```
