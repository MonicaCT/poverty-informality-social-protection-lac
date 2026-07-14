# Executive Summary

This repository is a reproducible Development Analytics project on poverty, labor informality and social-protection coverage in Latin America and the Caribbean.

## Policy Problem

Poverty, informal employment and social-protection gaps are usually monitored through separate data systems. This makes it difficult for policy teams to compare countries, identify data gaps, and interpret whether vulnerability is driven mainly by poverty levels, labor-market structure, social-protection coverage, inequality or macroeconomic context.

## Objective

The project builds a harmonized country-year panel and public dashboard to support descriptive policy analysis across Latin America and the Caribbean. It is designed for cautious comparison, monitoring and stakeholder communication, not for causal claims.

## Countries and Period

- Full harmonized panel: 1,789 country-year rows.
- Countries: 27.
- Full coverage: 1946-2025.
- Preferred analysis window: 2000-2023.
- Preferred analysis sample: 648 country-year rows.
- Complete model-ready sample: 178 rows, 17 countries, 2006-2023.

## Sources

The panel combines indicators from SEDLAC, World Development Indicators, ILOSTAT, ASPIRE, CEPALSTAT, World Bank Gini and Equity Lab-derived country-year outputs.

## Indicators

Core indicators include monetary poverty, extreme poverty, labor informality, unemployment, employment, labor-force participation, social-protection coverage, social-insurance coverage, social-assistance coverage, cash-transfer coverage, public social expenditure, Gini, GDP per capita and the Structural Vulnerability Index.

## Main Existing Findings

- The validation metadata report 0 duplicate country-year rows and 0 impossible percentage values.
- Social-protection and informality series are the binding missingness constraints.
- The dashboard supports country profiles, rankings, Bolivia context and descriptive policy views.
- Bolivia appears in the 2023 country ranking with monetary poverty of 16.5, labor informality of 83.882 and a Structural Vulnerability Index of -0.258 in the existing table.
- The Structural Vulnerability Index is a descriptive comparison tool, not a causal estimate or automatic policy ranking.

## Decisions Supported

- Which countries and years have enough information for cross-country comparison.
- Where poverty, informality and social-protection gaps coincide.
- Which variables constrain analytical completeness.
- How Bolivia compares with regional benchmarks in the public dashboard.
- Which indicators require careful caveats before policy interpretation.

## Limitations

- Missingness is substantial for social protection, informality and some labor-market indicators.
- Countries and years are not uniformly covered.
- Definitions vary across sources and require comparability caveats.
- Rankings are diagnostic views, not causal policy prescriptions.
- Full raw rebuild requires local source archives and is not part of this Stage 1B update.

## Available Products

- GitHub Pages website.
- Interactive dashboard.
- Processed country-year panel.
- Dashboard panel.
- Codebook and data dictionary.
- Validation report.
- Data lineage documentation.
- Figures and descriptive tables.
- Repository tests and reproducibility guide.
- SQL-ready documentation and placeholder SQL assets for future Tableau and analytical warehouse stages.
