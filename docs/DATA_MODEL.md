# Data Model

This document proposes the dimensional model for future Tableau and SQL work. It is based on existing public country-year variables and does not create a DuckDB database in Stage 1B.

## Current Analytical Grain

The public analytical grain is one row per `iso3` and `year` in the processed panel.

Primary analytical key:

```text
iso3 + year
```

## Dimensions

| dimension | grain | primary key | attributes | source | status |
|---|---|---|---|---|---|
| `dim_country` | one row per country | `iso3` | `country_name`, `region_lac`, `bolivia` | processed panel | PLANNED SQL-ready |
| `dim_time` | one row per year | `year` | decade, preferred analysis window flag | processed panel | PLANNED SQL-ready |
| `dim_indicator` | one row per indicator | `indicator_code` | policy domain, unit, definition, source | variable catalog | PLANNED SQL-ready |
| `dim_population_group` | one row per population group | `population_group_key` | total, women, men, youth, poorest quintile | inferred from existing variables | REVIEW_REQUIRED |
| `dim_source` | one row per source | `source_key` | source name, role, coverage note | source provenance | PLANNED SQL-ready |
| `dim_policy_domain` | one row per domain | `policy_domain_key` | poverty, labor, social protection, macro, inequality, quality | derived from catalog | PLANNED SQL-ready |

## Facts

| fact | grain | primary key | foreign keys | measures | comparability constraints | privacy constraints | status |
|---|---|---|---|---|---|---|---|
| `fact_poverty` | country-year | `iso3`, `year` | `iso3`, `year`, indicator/source keys | `monetary_poverty`, `extreme_poverty`, `poverty_gap` | poverty line and fallback definitions vary | aggregate country-year only | PLANNED SQL-ready |
| `fact_labor` | country-year | `iso3`, `year` | `iso3`, `year`, indicator/source keys | `unemployment`, `employment`, `labor_force_participation`, gender labor variables | labor definitions and missingness vary | aggregate country-year only | PLANNED SQL-ready |
| `fact_informality` | country-year | `iso3`, `year` | `iso3`, `year`, indicator/source keys | `labor_informality`, `labor_informality_lag1` | ILOSTAT and fallback definitions vary | aggregate country-year only | PLANNED SQL-ready |
| `fact_social_protection` | country-year | `iso3`, `year` | `iso3`, `year`, indicator/source keys | `social_protection_coverage`, social assistance, insurance, pension and adequacy variables | ASPIRE/WDI definitions and coverage vary | aggregate country-year only | PLANNED SQL-ready |
| `fact_vulnerability` | country-year | `iso3`, `year` | `iso3`, `year` | `structural_vulnerability_index`, `gini`, `gdp_per_capita`, `log_gdp_per_capita` | index is descriptive and component availability varies | aggregate country-year only | PLANNED SQL-ready |
| `fact_data_quality` | variable or country-year | REVIEW_REQUIRED | indicator, country, year keys | missingness rate, duplicate flags, impossible percentage flags, coverage counts | quality checks differ by variable | no raw data | PLANNED SQL-ready |

## Relationship Rules

- Country dimension filters all country-year facts by `iso3`.
- Time dimension filters all country-year facts by `year`.
- Indicator, source and policy-domain dimensions should be used for long-form Tableau extracts in a later stage.
- The current processed panel is wide; a future SQL/Tableau layer may expose long-form marts without recalculating indicators.

## Tableau Preparation

The first Tableau-ready model should prioritize:

1. executive overview mart;
2. poverty profile mart;
3. informality profile mart;
4. social-protection profile mart;
5. country benchmark mart;
6. data-quality mart.

## Constraints

- Do not join to raw microdata.
- Do not treat missing social-protection values as zero.
- Do not rank countries without missingness and comparability notes.
- Do not claim causal effects from descriptive panels.
- Do not publish private local source paths.
