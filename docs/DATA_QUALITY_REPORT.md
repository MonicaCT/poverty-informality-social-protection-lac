# Data Quality Report

This report summarizes existing validation evidence. No pipeline, model, indicator, table or figure was rerun for Stage 1B.

## Summary

| check | status | evidence | interpretation |
|---|---|---|---|
| country-year duplicates | PASS | validation metadata report 0 duplicate country-year rows | Country-year keys are unique in the built panel. |
| impossible percentage values | PASS | validation metadata report 0 impossible percentage values | Percentage domains passed existing validation. |
| temporal coverage | WARNING | full range 1946-2025; preferred analysis window 2000-2023 | Coverage is broad but not uniform by indicator. |
| country coverage | WARNING | 27 countries, but indicator availability differs | Country inclusion does not imply complete variables. |
| complete-case sample | WARNING | complete model-ready sample has 178 rows, 17 countries, 2006-2023 | Complete-case analysis is much smaller than the full panel. |
| missingness | WARNING | social protection and informality are binding constraints | Missingness reflects source coverage and limits analysis. |
| source lineage | PASS | `docs/DATA_LINEAGE.md`, `data/metadata/source_provenance.csv` | Main sources and roles are documented. |
| poverty definitions | WARNING | WDI preferred lines with Equity Lab fallback | Definition harmonization is documented but requires caveats. |
| informality definitions | WARNING | ILOSTAT informal employment with Equity Lab fallbacks | Definitions vary and should be interpreted cautiously. |
| social protection coverage | WARNING | ASPIRE with WDI fallback | High missingness and source-specific definitions constrain comparisons. |
| geographic consistency | PASS | standardized ISO3, country names and LAC regions | Existing metadata support geographic joins and grouping. |
| public privacy | PASS | country-year aggregate panel and dashboard outputs | No microdata or personal identifiers are published. |
| Tableau readiness | PLANNED | no Tableau artifact exists | Tableau should not be claimed as complete. |

## Missingness Constraints

Existing table 5 and validation metadata identify high missingness for social protection coverage, labor informality, gender labor indicators, youth unemployment and public expenditure variables. These constraints should be shown as part of the analysis, not hidden.

## Quality States

| domain | state | note |
|---|---|---|
| duplicates | PASS | 0 duplicate country-year rows in existing validation. |
| out-of-range percentages | PASS | 0 impossible percentage values in existing validation. |
| source comparability | WARNING | multiple sources and fallback definitions require caveats. |
| social-protection coverage | WARNING | high missingness. |
| informality coverage | WARNING | high missingness. |
| complete-case modeling | WARNING | sample shrinks to 178 rows. |
| raw-source rebuild | NOT TESTED | not executed in Stage 1B. |
| SQL execution | NOT TESTED | SQL assets are documentation-ready and not executed. |
| Tableau artifact | REVIEW_REQUIRED | planned for a later stage. |
