# Tableau Data Source Model

Status: PENDING MANUAL TABLEAU BUILD

This model uses only public aggregate CSV files created from existing repository outputs. It does not use raw data, does not recalculate indicators and does not create a Tableau workbook in Stage 2.

## Data Sources

| table | file | grain | role | status |
|---|---|---|---|---|
| `dim_country` | `tableau/data/dim_country.csv` | country | country and region dimension | AVAILABLE |
| `dim_time` | `tableau/data/dim_time.csv` | year | time dimension and analysis-window flag | AVAILABLE |
| `dim_indicator` | `tableau/data/dim_indicator.csv` | indicator | indicator metadata and source traceability | AVAILABLE |
| `dim_policy_domain` | `tableau/data/dim_policy_domain.csv` | policy domain | groups indicators into policy domains | AVAILABLE |
| `fact_poverty` | `tableau/data/fact_poverty.csv` | country-year | poverty indicators | AVAILABLE |
| `fact_labor` | `tableau/data/fact_labor.csv` | country-year | employment and unemployment indicators | AVAILABLE |
| `fact_informality` | `tableau/data/fact_informality.csv` | country-year | labor informality indicators | AVAILABLE |
| `fact_social_protection` | `tableau/data/fact_social_protection.csv` | country-year | social protection indicators | AVAILABLE |
| `fact_vulnerability` | `tableau/data/fact_vulnerability.csv` | country-year | vulnerability, inequality and macro context | AVAILABLE |
| `fact_data_quality` | `tableau/data/fact_data_quality.csv` | variable | missingness and quality diagnostics | AVAILABLE |

## Logical Model

Use Tableau relationships, not physical joins, to avoid row multiplication. Country and year are the main dimensions. Indicator and policy-domain relationships support the Data Quality dashboard and indicator metadata views.

## Relationship Rules

- Relate country facts to `dim_country` by `iso3`.
- Relate country-year facts to `dim_time` by `year`.
- Relate `fact_data_quality[variable]` to `dim_indicator[indicator_code]`.
- Relate `dim_indicator[policy_domain_key]` to `dim_policy_domain[policy_domain_key]`.
- Keep relationships at the logical layer unless Tableau requires a physical extract for performance.

## Comparability Constraints

- Social-protection coverage has high missingness and source-specific definitions.
- Labor informality combines ILOSTAT and documented fallbacks.
- Poverty uses WDI preferred lines and documented fallbacks.
- The Structural Vulnerability Index is descriptive and should not be treated as a causal score.

## Privacy Constraints

All tables are country-year or variable-level aggregate outputs. No microdata, household records, names, addresses, phone numbers, emails or credentials are included.
