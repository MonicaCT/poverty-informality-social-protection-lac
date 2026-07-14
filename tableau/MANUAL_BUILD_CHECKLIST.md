# Manual Tableau Build Checklist

Status: PENDING MANUAL TABLEAU BUILD

## Import Data

- [ ] Import `tableau/data/dim_country.csv`.
- [ ] Import `tableau/data/dim_time.csv`.
- [ ] Import `tableau/data/dim_indicator.csv`.
- [ ] Import `tableau/data/dim_policy_domain.csv`.
- [ ] Import `tableau/data/fact_poverty.csv`.
- [ ] Import `tableau/data/fact_labor.csv`.
- [ ] Import `tableau/data/fact_informality.csv`.
- [ ] Import `tableau/data/fact_social_protection.csv`.
- [ ] Import `tableau/data/fact_vulnerability.csv`.
- [ ] Import `tableau/data/fact_data_quality.csv`.

## Model

- [ ] Create relationships from `tableau/model/RELATIONSHIPS.csv`.
- [ ] Keep relationships logical where possible.
- [ ] Do not create many-to-many joins unless Tableau requires and the result is validated.
- [ ] Confirm row counts after relationships.

## Calculations and Parameters

- [ ] Create calculated fields from `tableau/calculations/`.
- [ ] Create parameters from `tableau/model/PARAMETER_CATALOG.csv`.
- [ ] Do not use fields marked `REVIEW_REQUIRED - DO NOT USE`.

## Dashboards and Story

- [ ] Build exactly five dashboards.
- [ ] Build one story with six points maximum.
- [ ] Use wireframes from `tableau/wireframes/`.
- [ ] Configure filters, actions, tooltips and reset controls.
- [ ] Keep methodology and missingness warnings visible.

## Export

- [ ] Save real workbook under `tableau/workbook/`.
- [ ] Export real PDF only after QA.
- [ ] Create real screenshots only after QA.
- [ ] Do not commit fake workbook, PDF or screenshots.
