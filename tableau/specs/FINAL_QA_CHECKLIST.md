# Final QA Checklist

## Data

- [ ] Only `tableau/data/` CSVs are used.
- [ ] No raw data source is connected.
- [ ] Row counts match the package.
- [ ] Country and year fields are typed correctly.
- [ ] Percent fields are numeric.

## Model

- [ ] Relationships match `tableau/model/RELATIONSHIPS.csv`.
- [ ] No physical join creates duplicate country-year rows.
- [ ] `fact_data_quality` relates to `dim_indicator` by variable/indicator code.
- [ ] Policy domains relate to indicator metadata.

## Calculations and Parameters

- [ ] Calculated fields match `tableau/model/CALCULATED_FIELD_CATALOG.csv`.
- [ ] `REVIEW_REQUIRED` fields are not used.
- [ ] Seven planned parameters are created only if useful.
- [ ] Metric selector works without hiding methodology notes.

## Dashboards and Story

- [ ] Exactly five dashboards exist.
- [ ] One story exists with maximum six points.
- [ ] Navigation works.
- [ ] Reset filters works.
- [ ] Tooltips show units and caveats.
- [ ] Missing data are visible.

## Privacy and Export

- [ ] No private paths are visible.
- [ ] No credentials are visible.
- [ ] No raw or personal data are visible.
- [ ] PDF export is real if produced.
- [ ] Screenshots are real if produced.
- [ ] No fake `.twb`, `.twbx`, PDF or screenshots are committed.
