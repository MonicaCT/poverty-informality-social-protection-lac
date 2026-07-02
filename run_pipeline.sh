#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON:-python}"
RSCRIPT_BIN="${RSCRIPT:-Rscript}"
FULL_RAW_REBUILD="${1:-}"

run_step() {
  echo "==> $1"
  shift
  "$@"
}

if [[ "$FULL_RAW_REBUILD" == "--full-raw-rebuild" ]]; then
  run_step "Build data inventory" "$PYTHON_BIN" code/python/00_build_data_inventory.py
  run_step "Build harmonized panel" "$PYTHON_BIN" code/python/01_build_panel.py
else
  echo "==> Skipping raw-source rebuild; using included processed panel."
  echo "    Run ./run_pipeline.sh --full-raw-rebuild to rebuild from configured local source archives."
fi

run_step "Generate descriptive tables and figures" "$PYTHON_BIN" code/python/02_descriptive_analysis.py
run_step "Build dashboard" "$PYTHON_BIN" code/python/03_build_dashboard.py
run_step "Estimate econometric models" "$RSCRIPT_BIN" code/r/03_econometric_models.R
run_step "Generate documents" "$PYTHON_BIN" code/python/04_generate_documents.py
run_step "Run panel integrity tests" "$PYTHON_BIN" tests/test_panel_integrity.py
run_step "Run output tests" "$PYTHON_BIN" tests/test_repository_outputs.py
run_step "Run publication readiness tests" "$PYTHON_BIN" tests/test_publication_readiness.py
