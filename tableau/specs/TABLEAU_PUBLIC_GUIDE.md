# Tableau Public Guide

Status: PENDING MANUAL TABLEAU BUILD

Publish to Tableau Public only after a real workbook exists and passes `tableau/specs/FINAL_QA_CHECKLIST.md`.

## Safe Publication Conditions

- Uses only `tableau/data/` aggregate CSVs.
- Contains no raw data.
- Contains no private local paths in captions, data-source names or tooltips.
- Contains no credentials.
- Does not include `REVIEW_REQUIRED` calculated fields.
- Includes visible missingness and comparability caveats.

## Do Not Publish If

- Any source points to a private local path.
- Any raw file is connected.
- Any dashboard hides missingness caveats.
- Any calculated field has an error.
- Any workbook artifact is simulated rather than created by Tableau.
