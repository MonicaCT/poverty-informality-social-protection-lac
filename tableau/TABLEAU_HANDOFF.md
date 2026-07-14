# Tableau Handoff

Status: PENDING MANUAL TABLEAU BUILD

## What Is Ready

- Public aggregate data package.
- Logical relationship model.
- Field dictionary.
- Calculated field catalog.
- Parameter catalog.
- Visual style guide.
- Five dashboard specifications.
- One story specification.
- Manual build guide and QA checklist.

## What Must Be Done Manually

1. Open Tableau Desktop or Tableau Public.
2. Import `tableau/data/` CSVs.
3. Create relationships.
4. Create calculated fields and parameters.
5. Build five dashboards and one story.
6. Run QA.
7. Save a real workbook and export real artifacts.

## What Must Not Be Modified

- Raw data.
- Processed panel values.
- Existing figures and tables.
- Existing web dashboard.
- Existing scripts or pipeline.
- Calculated fields marked `REVIEW_REQUIRED - DO NOT USE`.

## Definition of Success

- Workbook uses only public aggregate CSVs.
- Exactly five dashboards exist.
- One story exists with six points maximum.
- Missingness and comparability caveats are visible.
- No fake workbook, PDF or screenshots are created.
- Tableau Public is used only after privacy QA passes.
