PYTHON ?= python
RSCRIPT ?= Rscript

.PHONY: install reproduce test dashboard models docs raw-rebuild

install:
	$(PYTHON) -m pip install --upgrade pip
	$(PYTHON) -m pip install -r requirements.txt

reproduce:
	$(PYTHON) code/python/02_descriptive_analysis.py
	$(PYTHON) code/python/03_build_dashboard.py
	$(RSCRIPT) code/r/03_econometric_models.R
	$(PYTHON) code/python/04_generate_documents.py

raw-rebuild:
	$(PYTHON) code/python/00_build_data_inventory.py
	$(PYTHON) code/python/01_build_panel.py

models:
	$(RSCRIPT) code/r/03_econometric_models.R

dashboard:
	$(PYTHON) code/python/03_build_dashboard.py

docs:
	$(PYTHON) code/python/04_generate_documents.py

test:
	$(PYTHON) tests/test_panel_integrity.py
	$(PYTHON) tests/test_repository_outputs.py
	$(PYTHON) tests/test_publication_readiness.py
