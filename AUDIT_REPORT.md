# Internal Audit Report

Date: 2026-07-02

Scope: complete pre-publication audit of repository structure, README, documentation, code quality, reproducibility, data pipeline, metadata, figures, tables, econometric models, dashboard, policy brief, paper draft, interpretations, consistency, performance, maintainability, and GitHub presentation.

## Executive Assessment

The repository was functional before the audit, but it was not yet at flagship professional standard. The most important issues were econometric: conventional standard errors were being exported for several models, diagnostic tests were incomplete, GMM fragility was not prominent enough, and the model-sample count in the panel summary did not match the actual R estimation sample. These issues have been fixed.

## Critical Findings

| ID | Finding | Evidence | Fix | Status |
|---|---|---|---|---|
| C1 | Model tables did not consistently report robust or clustered standard errors. | Initial exports relied on default `broom::tidy` behavior for `lm` and `plm` models. | Rewrote `code/r/03_econometric_models.R` to export HC1 country-clustered SE for pooled OLS and plm models, country-clustered SE for fixest models, and robust GMM SE where available. | Fixed |
| C2 | Econometric diagnostics were insufficient for publication claims. | No formal VIF, heteroskedasticity, serial correlation, cross-sectional dependence, or diagnostic exports. | Added `econometric_diagnostics.csv/.md`, `multicollinearity_vif.csv`, and `gmm_diagnostics.md`. | Fixed |
| C3 | GMM models were estimated but not clearly demoted despite singular weighting-matrix warnings. | R emitted singular first- and second-step weighting matrix warnings. | Documentation, model status, interpretation, paper, README, and policy brief now mark GMM as robustness only. | Fixed |
| C4 | Main model sample count was inconsistent. | `panel_build_summary.json` counted rows without unemployment and not exactly as the R model sample. | `01_build_panel.py` now reports complete preferred-model rows, countries, and years using the actual model covariate set and analysis window. | Fixed |

## Major Findings

| ID | Finding | Evidence | Fix | Status |
|---|---|---|---|---|
| M1 | README was too thin for a flagship portfolio repository. | Missing badges, diagrams, dashboard preview, data lineage, diagnostic summary, and methodology diagram. | Rewrote README with badges, Mermaid diagrams, dashboard preview, data lineage, model workflow, audited estimates, outputs, limitations. | Fixed |
| M2 | Dashboard was functional but not reproducible from a dedicated script and depended on external CDN. | `dashboard/index.html` existed, but no builder script was in the pipeline; Plotly loaded from web. | Added `code/python/03_build_dashboard.py`; dashboard is now self-contained and offline with embedded Plotly.js and generated preview. | Fixed |
| M3 | Paper and policy brief overstated preliminary interpretation and lacked diagnostic context. | Earlier text emphasized suggestive results without robust-inference caveats. | Rewrote paper draft and policy brief around audited robust results and limitations. | Fixed |
| M4 | Figure outputs lacked a machine-readable caption/interpretation catalog. | Figures existed, but reviewers had no structured captions. | Added `outputs/figures/figure_catalog.csv/.md` and upgraded PNG export to 400 dpi. | Fixed |
| M5 | Reproducibility tests were too narrow. | Only panel integrity was tested. | Added `tests/test_repository_outputs.py` for artifacts, diagnostics, robust SE, dashboard, and figure catalog. | Fixed |
| M6 | Data licensing and source terms were underdocumented. | No data license note; raw data are local and source governed. | Added `LICENSE`, `docs/DATA_LICENSE.md`, and clarified raw data are not redistributed. | Fixed |

## Minor Findings

| ID | Finding | Fix | Status |
|---|---|---|---|
| m1 | `run_pipeline.ps1` did not include dashboard generation or expanded tests. | Updated run order. | Fixed |
| m2 | `CITATION.cff` had a placeholder GitHub URL. | Removed placeholder because repository is not published yet. | Fixed |
| m3 | Documentation was scattered. | Added `DATA_LINEAGE.md`, `ECONOMETRIC_DIAGNOSTICS.md`, `MODEL_LIMITATIONS.md`, and improved strategy docs. | Fixed |
| m4 | Policy brief PDF generator used provisional text. | Updated generator to pull robust model estimates and diagnostics. | Fixed |
| m5 | Figure resolution was adequate but could be stronger. | Raised PNG export to 400 dpi. | Fixed |

## Cosmetic Findings

| ID | Finding | Fix | Status |
|---|---|---|---|
| c1 | Dashboard visual design felt like a prototype. | Rebuilt with IDB-style color palette, sidebar navigation, KPI cards, executive summary, responsive layout. | Fixed |
| c2 | README lacked visual entry point. | Added dashboard preview image. | Fixed |
| c3 | Some docs lacked clear reviewer-facing headings. | Reorganized with concise sections. | Fixed |

## Econometric Audit Details

- Preferred model observations: 178
- Preferred model countries: 17
- Preferred model years: 2006-2023
- Maximum VIF: 5.12
- Breusch-Pagan heteroskedasticity p-value: 1.22e-12
- Panel serial correlation p-value: 7.61e-08
- Pesaran cross-sectional dependence p-value: 0.000878
- Hausman p-value: 0.0313

Implication: fixed effects with robust country-clustered inference is the correct baseline. GMM remains a robustness check because instrument validity is weak in this finite sample.

## Remaining Non-Fixable Limitations

- The analysis remains associational, not causal.
- The complete model has 17 country clusters, making p-values finite-sample sensitive.
- Quarto is not installed locally, so `.qmd` files are prepared but not rendered.
- Stata is not available locally, so the Stata equivalent script is provided but not run.
- Raw source datasets are local and governed by provider terms; they should not be published without permissions.
