# Dashboard Build Order

| order | dashboard | purpose | primary tables | main visuals | validation |
|---:|---|---|---|---|---|
| 1 | Regional Executive Overview | Show regional variation, vulnerable countries and data gaps | all facts, `dim_country`, `dim_time` | KPI strip, ranking/map, trend, poverty-vs-informality, coverage, data warning | no blank KPIs; missingness warning visible |
| 2 | Poverty and Inequality | Explain poverty levels, extreme poverty and inequality context | `fact_poverty`, `fact_vulnerability` | poverty ranking, trend, extreme poverty, Bolivia benchmark, notes | no unconfirmed rural/urban view unless data exist |
| 3 | Labor and Informality | Compare informality, employment and unemployment | `fact_labor`, `fact_informality`, `fact_poverty` | informality trend, employment/unemployment cards, country comparison, scatter | source caveat visible |
| 4 | Social Protection | Show coverage, insurance, assistance and gaps | `fact_social_protection`, `fact_vulnerability` | coverage trend, assistance/insurance bars, gaps, protection-vulnerability view | missing coverage not treated as zero |
| 5 | Data Quality and Comparability | Make limitations visible | `fact_data_quality`, `dim_indicator`, `dim_policy_domain` | missingness bars, variable availability, source notes, warning table | high missingness highlighted |

## Story

Create one story named `Regional Policy Story` with six points: Regional context, Poverty, Informality, Social protection, Bolivia benchmark, Data limitations.
