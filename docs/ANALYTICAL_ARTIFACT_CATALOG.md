# Analytical Artifact Catalog

| artifact | type | analytical_purpose | source_file | visible_in_readme | visible_in_dashboard | reproducible | status |
|---|---|---|---|---|---|---|---|
| Processed LAC panel | processed dataset | Country-year analysis of poverty, informality, social protection and vulnerability indicators | `data/processed/lac_poverty_informality_social_protection_panel.csv` | Yes | No | Yes | Existing |
| Processed LAC panel parquet | processed dataset | Efficient analytical storage for the harmonized panel | `data/processed/lac_poverty_informality_social_protection_panel.parquet` | No | No | Yes | Existing |
| Dashboard panel | dashboard dataset | Compact data extract used by the interactive dashboard | `dashboard/dashboard_panel.csv` | Yes | Yes | Yes | Existing |
| Codebook | metadata | Variable definitions and field-level documentation | `data/metadata/CODEBOOK.md` | Yes | No | Yes | Existing |
| Validation report | validation | Documents row counts, country coverage, duplicates, impossible values and missingness | `data/metadata/validation_report.md` | Yes | No | Yes | Existing |
| Data lineage | documentation | Explains source flow from inventory to processed panel and public outputs | `docs/DATA_LINEAGE.md` | Yes | No | Yes | Existing |
| Dashboard | interactive dashboard | Explore country profiles, rankings, Bolivia context and descriptive policy views | `dashboard/index.html` | Yes | Yes | Yes | Existing |
| Dashboard documentation | documentation | Documents dashboard purpose, screenshots and rebuild command | `docs/dashboard.md` | Yes | No | Yes | Existing |
| Dashboard screenshots | visual documentation | Show overview, country profile and mobile layout for portfolio review | `assets/screenshots/` | No | No | Yes | Existing |
| Figure catalog | artifact index | Lists available publication figures and their interpretation | `outputs/figures/figure_catalog.md` | No | No | Yes | Existing |
| Figure 1: poverty evolution | figure | Track regional monetary poverty over time | `outputs/figures/figure_01_evolution_poverty.png` | Yes | No | Yes | Existing |
| Figure 2: informality evolution | figure | Track labor informality over time | `outputs/figures/figure_02_evolution_informality.png` | Yes | No | Yes | Existing |
| Figure 3: social protection coverage | figure | Summarize social-protection coverage patterns | `outputs/figures/figure_03_social_protection_coverage.png` | Yes | No | Yes | Existing |
| Figure 4: informality and poverty | figure | Show raw association between informality and poverty | `outputs/figures/figure_04_scatter_informality_poverty.png` | Yes | No | Yes | Existing |
| Figure 5: social protection and poverty | figure | Show raw association between social protection and poverty | `outputs/figures/figure_05_scatter_social_protection_poverty.png` | No | No | Yes | Existing |
| Figure 7: regional map | figure | Map structural vulnerability across countries | `outputs/figures/figure_07_regional_map.png` | No | No | Yes | Existing |
| Figure 8: country-year heatmap | figure | Show poverty persistence and coverage across country-years | `outputs/figures/figure_08_heatmap_country_year.png` | No | No | Yes | Existing |
| Figure 9: country ranking | figure | Rank latest observations by structural vulnerability | `outputs/figures/figure_09_country_ranking.png` | Yes | No | Yes | Existing |
| Figure 11: distributions | figure | Compare distributions of core indicators | `outputs/figures/figure_11_distribution.png` | No | No | Yes | Existing |
| Figure 12: Bolivia vs LAC | figure | Compare Bolivia's poverty trajectory with the regional average | `outputs/figures/figure_12_bolivia_vs_lac.png` | Yes | No | Yes | Existing |
| Table 1: descriptive statistics | table | Summarize distributions of core indicators | `outputs/tables/table_1_descriptive_statistics.md` | No | No | Yes | Existing |
| Table 2: correlation matrix | table | Show pairwise relationships among analytical variables | `outputs/tables/table_2_correlation_matrix.md` | No | No | Yes | Existing |
| Table 3: country ranking | table | Present latest structural vulnerability country ranking | `outputs/tables/table_3_country_ranking.md` | No | No | Yes | Existing |
| Table 4: regional summary | table | Summarize indicators by regional grouping | `outputs/tables/table_4_regional_summary.md` | No | No | Yes | Existing |
| Table 5: missing values | table | Document missingness patterns in analytical variables | `outputs/tables/table_5_missing_values.md` | No | No | Yes | Existing |
| Repository tests | validation | Check panel integrity, outputs and publication readiness | `tests/` | Yes | No | Yes | Existing |
| Reproducibility guide | documentation | Explain public workflow from processed panel to dashboard checks | `docs/reproducibility.md` | No | No | Yes | Existing |
| Repository architecture | documentation | Describe repository structure and artifact organization | `docs/repository-architecture.md` | Yes | No | Yes | Existing |
| Data license notes | documentation | Clarify source and reuse considerations | `docs/DATA_LICENSE.md` | Yes | No | Yes | Existing |