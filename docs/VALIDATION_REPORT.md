# Validation Report - Poverty, Informality and Social Protection Website

Date: 2026-07-13

## Scope

Final web-quality and static publication repair for the Poverty, Informality and Social Protection in Latin America repository.

## Dashboard decision

`dashboard/dashboard.qmd` uses the existing dashboard workflow and the repository already contains non-empty rendered dashboard HTML files:

- `dashboard/index.html`
- `docs/dashboard/index.html`

The rendered HTML in `docs/dashboard/index.html` does not require `dashboard_panel.csv` as an external relative file. Because the dashboard product is already rendered and non-empty, no Quarto render was executed in this phase.

Publication note:

```text
Interactive dashboard source available; static portfolio view published
```

## Reused products

- Interactive dashboard: `docs/dashboard/index.html`
- Dashboard source: `dashboard/dashboard.qmd`
- Dashboard panel: `dashboard/dashboard_panel.csv`
- Figures: `docs/assets/figures/figure_01_evolution_poverty.png`, `figure_02_evolution_informality.png`, `figure_03_social_protection_coverage.png`, `figure_04_scatter_informality_poverty.png`, `figure_07_regional_map.png`, `figure_08_heatmap_country_year.png`, `figure_09_country_ranking.png`, `figure_12_bolivia_vs_lac.png`
- Tables: `outputs/tables/table_1_descriptive_statistics.html`, `table_3_country_ranking.html`, `table_4_regional_summary.html`, `table_5_missing_values.html`
- Documentation: `docs/DATA_LINEAGE.md`, `docs/DATA_LICENSE.md`, `docs/reproducibility.md`, `docs/repository-architecture.md`, `docs/ANALYTICAL_ARTIFACT_CATALOG.md`

## Validation checklist

| Check | Status | Notes |
|---|---|---|
| `docs/index.html` exists | PASS | New static portfolio entry point created. |
| CSS and JavaScript exist | PASS | Shared reusable template copied exactly from `MonicaCT/site-template`. |
| Images referenced by website exist | PASS | Referenced local images are present under `docs/assets/`. |
| Tables referenced by website exist | PASS | Existing tables are linked via GitHub because `outputs/` is outside `/docs`. |
| Dashboard publication | PASS | `docs/dashboard/index.html` exists and is non-empty. |
| Dashboard source | PASS | `dashboard/dashboard.qmd` preserved. |
| README product links | PASS | Top README buttons point to Website, Dashboard, Figures, Tables, Methodology, Data Dictionary, Repository and Portfolio. |
| Back to Portfolio | PASS | Present in website and README. |
| Local Windows paths | PASS | No Windows local paths were introduced. |
| Private data patterns | PASS | No phone-number or credential-like strings were introduced. |
| Scientific content | PASS | No data, models, indicators, figures, tables or papers were modified. |
| Pipeline execution | PASS | No scripts, models, Quarto render or full pipeline were executed. |
| GitHub Pages | WARNING | Repository is prepared for `main` / `/docs`; public deployment depends on repository Pages settings. |

## GitHub Pages expected configuration

```text
Source: Deploy from a branch
Branch: main
Folder: /docs
```

If the public URL returns 404, classify it as:

```text
PENDING HUMAN PAGES CONFIGURATION
```

---

# Stage 1B Validation Addendum

Date: 2026-07-14

Scope: minimum flagship analytics standard for `poverty-informality-social-protection-lac`.

## Summary

Status: PASS

Stage 1B created flagship documentation and visible SQL assets using existing README content, metadata, dashboard files, public outputs, figures, tables and validation reports. No data were downloaded, no pipeline was executed, no indicator was recalculated, no model was run, no figure or table was regenerated and no dashboard was rebuilt.

## Checks

| Check | Status | Notes |
|---|---|---|
| Documents created | PASS | Executive summary, recruiter guide, variable catalog, KPI dictionary, data-quality report, stakeholder requirements, data model and flagship status exist. |
| KPI consistency | PASS | KPI names and definitions reuse existing panel variables, README, dashboard and metadata. |
| Variables not invented | PASS | Variables are taken from existing data dictionary and dashboard panel; uncertain fields use `REVIEW_REQUIRED`. |
| Tableau status | PASS | Tableau is marked `PLANNED`; no Tableau artifact is claimed. |
| SQL assets | PASS | DDL, marts and validation SQL were created as future SQL/Tableau assets and were not executed. |
| Privacy | PASS | Documentation and SQL refer only to public aggregate country-year data. |
| Data unchanged | PASS | No files under `data/`, `dashboard/`, `outputs/`, `reports/`, `models/`, `paper/`, `scripts/`, `src/` or `docs/index.html` were modified. |
| Results unchanged | PASS | No indicators, models, tables, figures or dashboard outputs were recalculated. |
