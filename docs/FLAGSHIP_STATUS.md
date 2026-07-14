# Flagship Status

| component | status | evidence | next action |
|---|---|---|---|
| website | COMPLETE | `docs/index.html` and GitHub Pages-ready documentation | maintain links only |
| executive summary | COMPLETE | `docs/EXECUTIVE_SUMMARY.md` | use in README navigation |
| recruiter guide | COMPLETE | `docs/RECRUITER_GUIDE.md` | use for portfolio review |
| variable catalog | COMPLETE | `docs/VARIABLE_CATALOG.md` | refine only if new public data model is built |
| KPI dictionary | COMPLETE | `docs/KPI_DICTIONARY.md` | align Tableau measures later |
| stakeholder requirements | COMPLETE | `docs/STAKEHOLDER_REQUIREMENTS.md` | use for Tableau storyboard |
| data-quality report | COMPLETE | `docs/DATA_QUALITY_REPORT.md` | preserve caveats in dashboard stages |
| data model | COMPLETE | `docs/DATA_MODEL.md` | implement in Tableau or DuckDB only when authorized |
| SQL DDL | COMPLETE | `sql/ddl/` | execute only against approved public tables |
| SQL marts | COMPLETE | `sql/marts/` | use as future Tableau extract logic |
| SQL validation | COMPLETE | `sql/validation/` | run only when SQL database exists |
| dashboard web | COMPLETE | `dashboard/index.html`, `docs/dashboard/index.html` | do not rebuild in Stage 1B |
| Tableau | PLANNED | no Tableau artifact exists | Stage 2 candidate |
| Power BI | NOT REQUIRED | Tableau is planned for this repository; Power BI not requested | no action |
| paper/report | PARTIAL | dashboard documentation, release notes and validation assets exist; no standalone paper | consider later only if authorized |
| reproducibility | COMPLETE | `docs/reproducibility.md`, tests and pipeline scripts | do not rerun in Stage 1B |
| privacy | COMPLETE | public country-year aggregate outputs; no raw data redistributed | maintain no raw-data policy |
| public deployment | COMPLETE | repository prepared for GitHub Pages under `/docs` | human Pages settings if needed |
