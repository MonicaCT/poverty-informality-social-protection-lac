# Poverty, Informality, and Social Protection in LAC

![Status](https://img.shields.io/badge/status-interactive%20dashboard-0B2F44)
![Scope](https://img.shields.io/badge/scope-Latin%20America%20and%20Caribbean-2F5F8F)
![Reproducibility](https://img.shields.io/badge/reproducible-data%20analytics-6F8F7A)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

![Repository banner](assets/brand/repository-banner.png)

## Overview

This repository contains an interactive research dashboard on poverty, labor informality, social protection, and structural vulnerability in Latin America and the Caribbean. It is organized as a data analytics and visualization project for policy audiences, international organizations, and applied development research portfolios.

The dashboard summarizes a reproducible country-year panel and presents descriptive evidence through institutional-style indicators, country profiles, rankings, and high-level regional patterns.

## Data

The project uses a harmonized country-year panel combining indicators from:

- SEDLAC
- World Development Indicators
- ILOSTAT
- ASPIRE
- CEPALSTAT

The main dashboard input is:

`dashboard/dashboard_panel.csv`

The broader processed panel is stored in:

`data/processed/lac_poverty_informality_social_protection_panel.csv`

## Dashboard

The Quarto dashboard is located at:

`dashboard/dashboard.qmd`

The rendered dashboard is located at:

`dashboard/index.html`

It presents:

- summary indicators for countries, years, observations, poverty, informality, and social protection
- a structural vulnerability ranking
- a Bolivia country profile
- concise research-question and methodology panels
- descriptive policy-oriented interpretation

## Indicators

Core variables include:

- monetary poverty
- extreme poverty
- labor informality
- social protection coverage
- GDP per capita
- unemployment
- gender labor indicators
- inequality indicators

Variable definitions and provenance are documented in:

`data/metadata/CODEBOOK.md`

## Structural Vulnerability Index

The dashboard includes a composite Structural Vulnerability Index constructed from normalized indicators of poverty, informality, social protection, GDP per capita, and gender labor conditions. Higher values indicate greater structural vulnerability.

The index is intended for descriptive comparison across countries and years. It should be interpreted as a visualization and diagnostic tool, not as a causal estimate.

## Interactive Visualizations

Key visual outputs include:

- latest structural vulnerability ranking
- regional trends in poverty, informality, and social protection
- country-year heatmaps
- Bolivia profile
- descriptive scatter plots
- country rankings and summary tables

Figures and tables are stored in:

`outputs/figures/`

`outputs/tables/`

## Country Profiles

The dashboard includes a focused Bolivia profile showing long-run changes in poverty, informality, social protection, and structural vulnerability. This profile is designed as an example of how the panel can support country-level descriptive analysis.

## How to Run

Open the rendered dashboard directly:

`dashboard/index.html`

To rebuild the dashboard in a local Quarto environment:

```bash
quarto render dashboard/dashboard.qmd
```

To rebuild the data and descriptive outputs from the existing project scripts:

```bash
powershell -ExecutionPolicy Bypass -File run_pipeline.ps1
```

## Repository Structure

```text
dashboard/        Quarto dashboard, dashboard panel, rendered HTML
data/             processed panel, metadata, validation files
code/python/      data construction and descriptive analysis scripts
outputs/figures/  dashboard and descriptive figures
outputs/tables/   dashboard and descriptive tables
docs/             dashboard documentation and GitHub Pages materials
assets/           repository banner, social preview, screenshots
tests/            repository integrity checks
```

## Reproducibility

The repository keeps source data documentation, processed dashboard inputs, validation metadata, rendered outputs, and scripts together so the visual analysis can be reproduced or audited on a clean machine.

## License

This project is released under the MIT License.
