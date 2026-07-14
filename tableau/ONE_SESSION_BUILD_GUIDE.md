# One-Session Tableau Build Guide

Build the workbook in one manual Tableau session using only public aggregate files.

## Block 1 - Create Workbook

1. Open Tableau Desktop or Tableau Public manually.
2. Create a new workbook.
3. Save as `poverty_informality_social_protection_lac.twbx` if packaging is available, otherwise `.twb`.
4. Recommended folder: `tableau/workbook/`.

## Block 2 - Import Sources

Import in this order:

1. `dim_country.csv`
2. `dim_time.csv`
3. `dim_policy_domain.csv`
4. `dim_indicator.csv`
5. `fact_poverty.csv`
6. `fact_labor.csv`
7. `fact_informality.csv`
8. `fact_social_protection.csv`
9. `fact_vulnerability.csv`
10. `fact_data_quality.csv`

Use the final table names without file extensions.

## Block 3 - Relationships

Create relationships exactly as documented in `tableau/model/RELATIONSHIPS.csv`.

Main keys:

- `iso3` for country relationships.
- `year` for time relationships.
- `indicator_code` to `variable` for quality metadata.
- `policy_domain_key` for domain grouping.

## Block 4 - Data Types

- `iso3`, `country_name`, `region_lac`, indicator and domain fields: String.
- `year`, `analysis_sample`, `bolivia`, `non_missing_obs`: Number whole.
- percentages, rates, indexes and GDP fields: Number decimal.

## Block 5 - Calculated Fields

Create calculations from `tableau/calculations/` by domain. Skip any item marked `REVIEW_REQUIRED - DO NOT USE`.

## Block 6 - Parameters

Create parameters from `tableau/model/PARAMETER_CATALOG.csv` only if they are used in a dashboard.

## Block 7 - Worksheets

Create worksheets for KPI cards, trends, rankings, scatter plots, social-protection coverage, missingness and source/comparability notes.

## Block 8 - Dashboards

Build the five dashboards from `tableau/specs/DASHBOARD_BUILD_ORDER.md` and wireframes.

## Block 9 - Story

Create one story named `Regional Policy Story` with six points maximum.

## Block 10 - Validation and Export

Run `tableau/specs/FINAL_QA_CHECKLIST.md`. Export workbook, PDF and screenshots only if QA passes.
