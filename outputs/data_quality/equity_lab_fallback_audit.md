# Equity Lab Fallback Audit

## Scope

This audit reviews all country-year observations in the processed panel where `monetary_poverty` or `extreme_poverty` is filled from the Equity Lab fallback because the comparable WDI poverty series is missing.

## Decision Rule

For each fallback observation, the raw Equity Lab value is compared with the same-country WDI range for the same poverty concept in a nearby +/-5 year window. If fewer than two nearby WDI observations are available, the rule uses all available WDI observations for that country. A fallback value is excluded when it falls clearly outside a conservative WDI-compatible band based on the nearby range and dispersion. Excluded values are retained as raw fields but set to missing in audited output columns.

## Results

- Total fallback observations audited: 170.
- Excluded as WDI-scale incompatible: 108.
- Retained as WDI-scale compatible: 62.
- Monetary poverty exclusions: 75.
- Extreme poverty exclusions: 33.
- Lagged monetary poverty exclusions in the audited panel: 75.
- Main complete-case analytic sample impact: 0 of 178 observations.

## Definition Check

Local Equity Lab metadata identifies the source variable as `poverty_8_30_2021_ppp` with detail `By country`, but does not document the exact scale, transformation, or harmonization convention used in the local extract. A short public documentation search found that the World Bank updated the upper-middle-income-country poverty line to USD 8.30 per person per day in 2021 PPP terms in the June 2025 global poverty update, and that PIP allows users to set poverty lines. However, the exact local Equity Lab column definition and scale could not be verified within the assigned search window. The column is therefore treated as a potentially relevant raw indicator, not as a mechanically comparable WDI-scale fallback whenever the audit flags scale inconsistency.

Sources checked:

- World Bank factsheet, June 5, 2025: https://www.worldbank.org/en/news/factsheet/2025/06/05/june-2025-update-to-global-poverty-lines
- World Bank blog, June 5, 2025: https://blogs.worldbank.org/en/voices/further-strengthening-how-we-measure-global-poverty
- World Bank Poverty and Inequality Platform: https://pip.worldbank.org/

## Files

- Strict audit table: `outputs/data_quality/equity_lab_fallback_audit.csv`.
- Audit table with lag flags: `outputs/data_quality/equity_lab_fallback_audit_detail.csv`.
- Non-canonical audited panel for future presentation/model reruns: `outputs/data_quality/lac_poverty_informality_social_protection_panel_audited.csv`.

The canonical processed panel is not overwritten in this step, so existing approved model outputs remain reproducible from the original canonical inputs. Future reruns should use the audited columns or rebuild the canonical panel with these exclusions applied.

