# Repository Architecture

This repository keeps research code, generated outputs, documentation, dashboard files, and publication assets separate.

| Folder | Purpose |
|---|---|
| `.github/` | CI, Pages workflow, issue templates, and pull request template. |
| `assets/` | Repository banner, social preview, and screenshots used by GitHub-facing documentation. |
| `code/` | Reproducible Python, R, Stata, and Quarto source files. |
| `config/` | Source-path and project configuration. |
| `data/` | Processed panel and metadata. Raw data are not redistributed. |
| `dashboard/` | Offline dashboard and dashboard data extract. |
| `docs/` | GitHub Pages documentation. |
| `outputs/` | Reproducible tables, figures, and model artifacts. |
| `paper/` | Research paper draft and bibliography. |
| `policy_brief/` | Policy brief source and PDF. |
| `releases/` | Release notes and publication packages. |
| `tests/` | Integrity, output, and publication-readiness checks. |

File names use descriptive lowercase stems for generated outputs, numbered prefixes for ordered figures and tables, and conventional uppercase names for repository entrypoints such as `README.md`, `LICENSE`, and `CITATION.cff`.
