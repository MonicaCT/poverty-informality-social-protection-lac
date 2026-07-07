# Repository Architecture

This repository is organized as an interactive data analytics and dashboard project.

| Folder | Purpose |
|---|---|
| `.github/` | CI, Pages workflow, issue templates, and pull request template. |
| `assets/` | Repository banner, social preview, and dashboard screenshots. |
| `code/python/` | Data inventory, panel construction, descriptive analysis, and dashboard generation scripts. |
| `config/` | Source-path and project configuration. |
| `data/` | Processed panel and metadata. Raw data are not redistributed. |
| `dashboard/` | Quarto dashboard, dashboard data extract, preview image, and rendered HTML. |
| `docs/` | GitHub Pages documentation for the dashboard and reproducibility workflow. |
| `outputs/` | Descriptive tables, dashboard figures, and data-quality outputs. |
| `releases/` | Dashboard release notes and publication packages. |
| `tests/` | Integrity, output, and dashboard-readiness checks. |

Generated outputs use descriptive lowercase file names. Ordered figures and tables retain numeric prefixes to make the dashboard workflow easy to audit.
