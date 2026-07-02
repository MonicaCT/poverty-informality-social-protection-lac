# Data Lineage

## Source Discovery

The pipeline begins with a recursive scan of the two local data archives specified by the project brief. The inventory extracts file-level metadata, variable names, approximate or exact observations, years, countries, merge keys, spatial identifiers, time identifiers, missingness, and likely research uses.

## Source Selection

The first analysis panel is built from harmonized country-year outputs, not directly from all raw microdata. This is intentional: the inventory shows that cross-country harmonized outputs are the appropriate first backbone, while household microdata require source-specific survey-weighted harmonization.

## Harmonized Sources

- ASPIRE: social protection coverage, adequacy, benefit incidence.
- Equity Lab: poverty, informality, gender labor indicators.
- ILOSTAT: labor informality and labor-market indicators.
- WDI: poverty benchmarks and macro controls.
- World Bank Gini: inequality.
- CEPAL: public social, education, health, and government expenditure.
- SEDLAC: income distribution extension and source audit.

## Derived Panel

The processed panel standardizes ISO3, country names, years, LAC region groups, percentage variables, lags, interaction terms, and a structural vulnerability index. Every derived variable is documented in `data/metadata/CODEBOOK.md`.
