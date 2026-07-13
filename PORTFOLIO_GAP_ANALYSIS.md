# Portfolio Gap Analysis

## 1. Existing Analytical Products

- Harmonized Latin America and Caribbean country-year panel: `data/processed/lac_poverty_informality_social_protection_panel.csv` and `.parquet`.
- Dashboard-ready analytical extract: `dashboard/dashboard_panel.csv`.
- Data inventory and metadata system: `DATA_INVENTORY.md`, `data/metadata/data_inventory_*.csv/json`, and `config/project_sources.yml`.
- Data lineage, codebook and data license documentation: `docs/DATA_LINEAGE.md`, `data/metadata/CODEBOOK.md`, `docs/DATA_LICENSE.md`.
- Validation outputs: `data/metadata/validation_report.md`, quality-control CSVs, and repository tests.
- Descriptive tables and figures for poverty, informality, social protection, vulnerability and Bolivia-LAC comparison.
- Static interactive dashboard: `dashboard/index.html` and `docs/dashboard/index.html`.
- Reproducibility materials: `requirements.txt`, `environment.yml`, `Makefile`, `run_pipeline.*`, and test files.

## 2. Available Figures

- Existing rendered figures in `outputs/figures`: Figures 1, 2, 3, 4, 5, 7, 8, 9, 11 and 12 as PNG/PDF where applicable.
- Interactive regional map exists as `outputs/figures/figure_07_regional_map.html`.
- GitHub Pages copies exist under `docs/assets/figures` for Figures 1, 2, 3, 4, 5, 7, 8, 9, 11 and 12.
- Dashboard screenshots exist in `assets/screenshots` and `docs/assets/screenshots`: overview, country profile and mobile layout.
- Figure catalog lists Figures 6 and 10, but the corresponding rendered files were not found in the current visible artifacts.

## 3. Available Tables

- `outputs/tables/table_1_descriptive_statistics` in CSV, HTML and Markdown.
- `outputs/tables/table_2_correlation_matrix` in CSV, HTML and Markdown.
- `outputs/tables/table_3_country_ranking` in CSV, HTML and Markdown.
- `outputs/tables/table_4_regional_summary` in CSV, HTML and Markdown.
- `outputs/tables/table_5_missing_values` in CSV, HTML and Markdown.
- Consolidated workbook: `outputs/tables/descriptive_tables.xlsx`.

## 4. Existing Dashboard

- Live dashboard is linked from the README at `https://monicact.github.io/poverty-informality-social-protection-lac/dashboard/`.
- Repository dashboard files are present: `dashboard/index.html`, `dashboard/dashboard.qmd`, `dashboard/dashboard_panel.csv`, and `dashboard/dashboard_preview.png`.
- Documentation is present in `docs/dashboard.md`.
- The dashboard uses Plotly and includes country selection, year filtering, rankings, Bolivia profile and descriptive policy views.

## 5. README Quality

- Strong overall README for a development-policy analytics portfolio: clear research question, findings, data sources, methodology, dashboard link, portfolio classification, reproducibility and citation.
- The README already communicates caution around causality and missingness, which is important for policy analytics credibility.
- The README is less optimized for a Data Analyst recruiter than it could be: Python, ETL, validation, dashboard delivery and output artifacts are present but could be surfaced more explicitly as a skills evidence block.
- No standalone paper is advertised, which is appropriate because the README states that no working paper is published for this repository.

## 6. Visible Evidence of Python, SQL, ETL, Validation and Dashboards

- Python: visible in `code/python/00_build_data_inventory.py`, `01_build_panel.py`, `02_descriptive_analysis.py`, and `03_build_dashboard.py`.
- ETL: visible through inventory scanning, panel construction, source harmonization, quality-control metadata and processed panel outputs.
- Validation: visible through `data/metadata/validation_report.md`, QC CSV files and tests in `tests/`.
- Dashboards: visible through `dashboard/index.html`, `dashboard/dashboard.qmd`, screenshots and GitHub Pages link.
- SQL: no clear SQL artifact or SQL query evidence was found in the visible repository files reviewed.

## 7. Presentation Problems

- `docs/index.md` has a Markdown typo in the navigation line: `dashboard.md` followed by a literal `` `n- `` sequence.
- `docs/index.md` references documentation files that were not found: `EMPIRICAL_STRATEGY.md`, `ECONOMETRIC_DIAGNOSTICS.md`, and `MODEL_LIMITATIONS.md`.
- `docs/index.md` references figure assets that were not found: `figure_06_interaction_plot.png` and `figure_10_coefficient_plot.png`.
- The main README is stronger than the docs landing page; the public documentation site may therefore undersell the repository.
- Recruiter-facing evidence exists but is distributed across README, metadata, tests, figures and dashboard rather than summarized in one high-signal section.

## 8. Broken Links

- `docs/README_LINK_AUDIT.md` reports README links as PASS: 40, WARNING: 0, FAIL: 0.
- Local inspection found unresolved references in `docs/index.md`:
  - `docs/EMPIRICAL_STRATEGY.md`;
  - `docs/ECONOMETRIC_DIAGNOSTICS.md`;
  - `docs/MODEL_LIMITATIONS.md`;
  - `docs/assets/figures/figure_06_interaction_plot.png`;
  - `docs/assets/figures/figure_10_coefficient_plot.png`.
- No README broken links were identified from the existing audit file.

## 9. Reusable Products

- Existing dashboard, dashboard screenshots and dashboard panel.
- Existing README structure, portfolio classification and GitHub Pages dashboard button.
- Processed panel and validation metadata.
- Existing figures 1, 2, 3, 4, 5, 7, 8, 9, 11 and 12.
- Existing tables 1-5 and descriptive workbook.
- Data lineage, codebook, data license notes, reproducibility guide and repository architecture docs.
- Tests and publication-readiness checks.

## 10. Missing Tasks

- Align `docs/index.md` with the files and figures that actually exist.
- Add a recruiter-facing skills evidence section to README using existing artifacts only.
- Add a compact outputs catalog linking dashboard, tables, figures, validation and processed data.
- Improve visibility of ETL and validation workflow without rerunning code.
- Decide whether SQL should be represented through a documentation-only query appendix based on the existing processed panel.

## 11. Task Classification

### HIGH IMPACT + LOW EFFORT

- Fix `docs/index.md` navigation typo and remove or replace missing local links.
- Align the docs figure table with the existing rendered figures.
- Add a compact README evidence block for Python ETL, validation, dashboarding and reproducibility.
- Add direct README links to the existing tables and validation report.

### HIGH IMPACT + MEDIUM EFFORT

- Build a polished public portfolio landing section using existing dashboard screenshots, figures and tables.
- Add a recruiter-oriented analytical-products map that connects business questions to artifacts.
- Add documentation-only SQL examples against the existing processed panel if SQL visibility is required.

### LOW PRIORITY

- Add a standalone paper, DOI or new release.
- Regenerate missing Figures 6 and 10.
- Rework the analytical methodology or data model.

## 12. Recommended Actions for the Next Phase

1. Fix only the broken `docs/index.md` references and Markdown typo.
2. Add a recruiter-facing skills evidence block to README.
3. Add a concise artifact catalog linking dashboard, figures, tables, validation and processed panel.
4. Improve GitHub Pages documentation using existing screenshots and figures only.
5. Add SQL visibility only as non-executed documentation based on the existing processed panel, if desired.
