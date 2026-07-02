# Data Validation Report

## Summary

- rows: 1789
- countries: 27
- years: 1946-2025
- duplicate_country_year_rows: 0
- impossible_percent_values: 0
- analysis_sample_rows: 648
- complete_main_model_rows: 178
- complete_main_model_countries: 17
- complete_main_model_years: 2006-2023

## Highest Missingness Variables

| variable                             |   missing_pct |
|:-------------------------------------|--------------:|
| sedlac_income_mean                   |         99.66 |
| poverty_gap_equity                   |         98.16 |
| cash_transfer_coverage_aspire        |         95.19 |
| informality_productivity_equity      |         94.63 |
| lfp_total_equity                     |         94.58 |
| female_labor_participation           |         94.58 |
| youth_unemployment                   |         94.58 |
| youth_unemployment_equity            |         94.58 |
| unemployment_equity                  |         94.58 |
| male_labor_participation             |         94.58 |
| male_lfp_equity                      |         94.58 |
| female_lfp_equity                    |         94.58 |
| informality_social_protection_equity |         94.58 |
| labor_income_gini_equity             |         94.19 |
| education_expenditure                |         91.39 |
| health_expenditure                   |         91.39 |
| government_expenditure_total         |         91.39 |
| social_expenditure                   |         91.39 |
| informality_x_social_protection      |         89.88 |
| public_transfer_benefit_q1_aspire    |         88.88 |
| social_protection_adequacy_aspire    |         88.88 |
| pension_coverage_aspire              |         88.76 |
| social_insurance_coverage_aspire     |         88.76 |
| social_protection_coverage           |         88.71 |
| social_protection_coverage_wdi       |         88.71 |

## Country Coverage

| iso3   | country_name        | region_lac      |   first_year |   last_year |   n_years |   poverty_obs |   informality_obs |   social_protection_obs |
|:-------|:--------------------|:----------------|-------------:|------------:|----------:|--------------:|------------------:|------------------------:|
| BRA    | Brazil              | Mercosur        |         1960 |        2025 |        66 |            42 |                16 |                      12 |
| CRI    | Costa Rica          | Central America |         1960 |        2025 |        66 |            39 |                16 |                      14 |
| ARG    | Argentina           | Mercosur        |         1960 |        2025 |        66 |            37 |                23 |                      13 |
| HND    | Honduras            | Central America |         1960 |        2025 |        66 |            36 |                12 |                      10 |
| URY    | Uruguay             | Mercosur        |         1960 |        2025 |        66 |            32 |                19 |                      13 |
| COL    | Colombia            | Andean          |         1951 |        2025 |        67 |            32 |                20 |                      12 |
| PAN    | Panama              | Central America |         1950 |        2025 |        67 |            32 |                21 |                      14 |
| SLV    | El Salvador         | Central America |         1960 |        2025 |        66 |            31 |                11 |                      14 |
| CHL    | Chile               | Southern Cone   |         1952 |        2025 |        67 |            31 |                16 |                       8 |
| MEX    | Mexico              | Mexico          |         1960 |        2025 |        66 |            31 |                28 |                       8 |
| ECU    | Ecuador             | Andean          |         1960 |        2025 |        66 |            31 |                24 |                      13 |
| DOM    | Dominican Republic  | Caribbean       |         1960 |        2025 |        66 |            30 |                26 |                      14 |
| PER    | Peru                | Andean          |         1960 |        2025 |        66 |            30 |                24 |                      15 |
| BOL    | Bolivia             | Andean          |         1950 |        2025 |        67 |            29 |                25 |                      14 |
| PRY    | Paraguay            | Mercosur        |         1960 |        2025 |        66 |            29 |                18 |                      16 |
| GTM    | Guatemala           | Central America |         1960 |        2025 |        66 |            28 |                18 |                       3 |
| NIC    | Nicaragua           | Central America |         1960 |        2025 |        66 |            27 |                 1 |                       3 |
| VEN    | Venezuela           | Andean          |         1960 |        2025 |        66 |            13 |                 1 |                       1 |
| JAM    | Jamaica             | Caribbean       |         1960 |        2025 |        66 |             9 |                 9 |                       3 |
| BLZ    | Belize              | Central America |         1960 |        2025 |        66 |             8 |                 0 |                       1 |
| HTI    | Haiti               | Caribbean       |         1950 |        2025 |        67 |             2 |                 1 |                       1 |
| SUR    | Suriname            | Caribbean       |         1960 |        2025 |        66 |             2 |                 1 |                       0 |
| TTO    | Trinidad and Tobago | Caribbean       |         1946 |        2025 |        67 |             2 |                 0 |                       0 |
| GUY    | Guyana              | Caribbean       |         1960 |        2025 |        66 |             2 |                 5 |                       0 |
| BRB    | Barbados            | Caribbean       |         1960 |        2025 |        66 |             1 |                 1 |                       0 |
| BHS    | Bahamas             | Caribbean       |         1953 |        2025 |        67 |             0 |                 1 |                       0 |
| CUB    | Cuba                | Caribbean       |         1960 |        2025 |        66 |             0 |                 0 |                       0 |

## Notes

- Impossible percentage values are written to `data/metadata/qc_impossible_values.csv`.
- The preferred empirical sample is `analysis_sample == 1`, covering 2000-2023.
- Missingness reflects source coverage, not only data quality; social protection and informality series are the binding constraints.
