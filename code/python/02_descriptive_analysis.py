"""Generate descriptive tables and publication-ready figures."""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import plotly.express as px
import seaborn as sns


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PANEL_PATH = PROJECT_ROOT / "data" / "processed" / "lac_poverty_informality_social_protection_panel.csv"
TABLE_DIR = PROJECT_ROOT / "outputs" / "tables"
FIGURE_DIR = PROJECT_ROOT / "outputs" / "figures"
DASHBOARD_DIR = PROJECT_ROOT / "dashboard"

TABLE_DIR.mkdir(parents=True, exist_ok=True)
FIGURE_DIR.mkdir(parents=True, exist_ok=True)
DASHBOARD_DIR.mkdir(parents=True, exist_ok=True)

sns.set_theme(style="whitegrid", context="paper", font_scale=1.1)
PALETTE = {
    "poverty": "#1b9e77",
    "informality": "#d95f02",
    "social": "#7570b3",
    "bolivia": "#e7298a",
    "lac": "#4d4d4d",
    "accent": "#66a61e",
}

MAIN_VARS = [
    "monetary_poverty",
    "extreme_poverty",
    "labor_informality",
    "social_protection_coverage",
    "female_labor_participation",
    "male_labor_participation",
    "unemployment",
    "youth_unemployment",
    "employment",
    "gdp_per_capita",
    "gini",
    "social_expenditure",
    "education_expenditure",
    "health_expenditure",
    "structural_vulnerability_index",
]


def save_table(df: pd.DataFrame, name: str) -> None:
    df.to_csv(TABLE_DIR / f"{name}.csv", index=False, encoding="utf-8-sig")
    df.to_html(TABLE_DIR / f"{name}.html", index=False, classes="table table-sm", float_format="%.3f")
    (TABLE_DIR / f"{name}.md").write_text(df.to_markdown(index=False), encoding="utf-8")


def save_fig(fig: plt.Figure, name: str) -> None:
    fig.tight_layout()
    fig.savefig(FIGURE_DIR / f"{name}.png", dpi=400, bbox_inches="tight")
    fig.savefig(FIGURE_DIR / f"{name}.pdf", bbox_inches="tight")
    plt.close(fig)


def descriptive_tables(panel: pd.DataFrame, sample: pd.DataFrame) -> dict[str, pd.DataFrame]:
    available = [c for c in MAIN_VARS if c in sample.columns]
    desc = sample[available].describe(percentiles=[0.25, 0.5, 0.75]).T.reset_index().rename(columns={"index": "variable"})
    desc = desc.rename(columns={"50%": "median"})
    desc = desc[["variable", "count", "mean", "std", "min", "25%", "median", "75%", "max"]].round(3)

    corr_vars = [
        "monetary_poverty",
        "labor_informality",
        "social_protection_coverage",
        "unemployment",
        "log_gdp_per_capita",
        "gini",
        "social_expenditure",
    ]
    corr_vars = [c for c in corr_vars if c in sample.columns]
    corr = sample[corr_vars].corr().round(3).reset_index().rename(columns={"index": "variable"})

    latest = sample.dropna(subset=["structural_vulnerability_index"]).sort_values("year").groupby("iso3").tail(1)
    ranking = latest[["iso3", "country_name", "region_lac", "year", "monetary_poverty", "labor_informality", "social_protection_coverage", "structural_vulnerability_index"]].copy()
    ranking = ranking.sort_values("structural_vulnerability_index", ascending=False).round(3)
    ranking["rank"] = range(1, len(ranking) + 1)
    ranking = ranking[["rank", "iso3", "country_name", "region_lac", "year", "monetary_poverty", "labor_informality", "social_protection_coverage", "structural_vulnerability_index"]]

    regional = (
        sample.groupby("region_lac")[["monetary_poverty", "labor_informality", "social_protection_coverage", "unemployment", "gdp_per_capita", "gini", "structural_vulnerability_index"]]
        .mean(numeric_only=True)
        .round(3)
        .reset_index()
        .sort_values("structural_vulnerability_index", ascending=False)
    )
    regional.insert(1, "countries", sample.groupby("region_lac")["iso3"].nunique().reindex(regional["region_lac"]).values)

    missing = panel[MAIN_VARS + ["iso3", "year"]].isna().mean().mul(100).round(2).reset_index().rename(columns={"index": "variable", 0: "missing_pct"})
    missing["non_missing_obs"] = missing["variable"].map(lambda c: int(panel[c].notna().sum()) if c in panel.columns else 0)
    missing = missing.sort_values("missing_pct", ascending=False)
    return {
        "table_1_descriptive_statistics": desc,
        "table_2_correlation_matrix": corr,
        "table_3_country_ranking": ranking,
        "table_4_regional_summary": regional,
        "table_5_missing_values": missing,
    }


def plot_lines(sample: pd.DataFrame, value: str, title: str, ylabel: str, color: str, filename: str) -> None:
    yearly = sample.groupby("year", as_index=False)[value].mean()
    fig, ax = plt.subplots(figsize=(8, 4.8))
    ax.plot(yearly["year"], yearly[value], color=color, linewidth=2.4)
    ax.scatter(yearly["year"], yearly[value], color=color, s=14)
    ax.set_title(title, loc="left", weight="bold")
    ax.set_xlabel("")
    ax.set_ylabel(ylabel)
    ax.grid(True, alpha=0.25)
    save_fig(fig, filename)


def figures(panel: pd.DataFrame, sample: pd.DataFrame, ranking: pd.DataFrame) -> None:
    plot_lines(sample.dropna(subset=["monetary_poverty"]), "monetary_poverty", "Figure 1. Evolution of Monetary Poverty in LAC", "Percent", PALETTE["poverty"], "figure_01_evolution_poverty")
    plot_lines(sample.dropna(subset=["labor_informality"]), "labor_informality", "Figure 2. Evolution of Labor Informality in LAC", "Percent", PALETTE["informality"], "figure_02_evolution_informality")
    plot_lines(sample.dropna(subset=["social_protection_coverage"]), "social_protection_coverage", "Figure 3. Social Protection Coverage in LAC", "Percent", PALETTE["social"], "figure_03_social_protection_coverage")

    fig, ax = plt.subplots(figsize=(6.6, 5.0))
    sns.regplot(data=sample, x="labor_informality", y="monetary_poverty", scatter_kws={"s": 30, "alpha": 0.75}, line_kws={"color": PALETTE["poverty"]}, ax=ax)
    ax.set_title("Figure 4. Informality and Poverty", loc="left", weight="bold")
    ax.set_xlabel("Labor informality (%)")
    ax.set_ylabel("Monetary poverty (%)")
    save_fig(fig, "figure_04_scatter_informality_poverty")

    fig, ax = plt.subplots(figsize=(6.6, 5.0))
    sns.regplot(data=sample, x="social_protection_coverage", y="monetary_poverty", scatter_kws={"s": 30, "alpha": 0.75}, line_kws={"color": PALETTE["social"]}, ax=ax)
    ax.set_title("Figure 5. Social Protection and Poverty", loc="left", weight="bold")
    ax.set_xlabel("Social protection coverage (%)")
    ax.set_ylabel("Monetary poverty (%)")
    save_fig(fig, "figure_05_scatter_social_protection_poverty")

    inter = sample.dropna(subset=["labor_informality", "social_protection_coverage", "monetary_poverty"]).copy()
    if not inter.empty:
        inter["sp_tercile"] = pd.qcut(inter["social_protection_coverage"], 3, labels=["Low coverage", "Middle coverage", "High coverage"], duplicates="drop")
        fig, ax = plt.subplots(figsize=(7.2, 5.0))
        sns.lineplot(data=inter, x="labor_informality", y="monetary_poverty", hue="sp_tercile", estimator=None, units="iso3", alpha=0.25, ax=ax, legend=False)
        sns.regplot(data=inter[inter["sp_tercile"].astype(str) == "Low coverage"], x="labor_informality", y="monetary_poverty", scatter=False, ax=ax, label="Low coverage", color="#d95f02")
        sns.regplot(data=inter[inter["sp_tercile"].astype(str) == "High coverage"], x="labor_informality", y="monetary_poverty", scatter=False, ax=ax, label="High coverage", color="#1b9e77")
        ax.legend(frameon=False)
        ax.set_title("Figure 6. Informality-Poverty Gradient by Social Protection", loc="left", weight="bold")
        ax.set_xlabel("Labor informality (%)")
        ax.set_ylabel("Monetary poverty (%)")
        save_fig(fig, "figure_06_interaction_plot")

    latest = sample.dropna(subset=["structural_vulnerability_index"]).sort_values("year").groupby("iso3").tail(1)
    if not latest.empty:
        map_fig = px.choropleth(
            latest,
            locations="iso3",
            color="structural_vulnerability_index",
            hover_name="country_name",
            hover_data=["year", "monetary_poverty", "labor_informality", "social_protection_coverage"],
            color_continuous_scale="RdYlGn_r",
            title="Figure 7. Structural Vulnerability in Latin America",
        )
        map_fig.update_geos(scope="south america", showcountries=True)
        map_fig.write_html(FIGURE_DIR / "figure_07_regional_map.html")
        try:
            map_fig.write_image(FIGURE_DIR / "figure_07_regional_map.png", scale=2)
        except Exception:
            regional_latest = latest.groupby("region_lac", as_index=False)["structural_vulnerability_index"].mean().sort_values("structural_vulnerability_index", ascending=False)
            fig, ax = plt.subplots(figsize=(7.2, 4.8))
            sns.barplot(data=regional_latest, y="region_lac", x="structural_vulnerability_index", color=PALETTE["social"], ax=ax)
            ax.set_title("Figure 7. Regional Structural Vulnerability", loc="left", weight="bold")
            ax.set_xlabel("Index")
            ax.set_ylabel("")
            save_fig(fig, "figure_07_regional_map")

    heat = sample.pivot_table(index="country_name", columns="year", values="monetary_poverty", aggfunc="mean")
    if not heat.empty:
        fig, ax = plt.subplots(figsize=(11, max(5, 0.25 * len(heat))))
        sns.heatmap(heat, cmap="YlGnBu", linewidths=0.05, linecolor="white", ax=ax, cbar_kws={"label": "Poverty (%)"})
        ax.set_title("Figure 8. Country-Year Poverty Heatmap", loc="left", weight="bold")
        ax.set_xlabel("")
        ax.set_ylabel("")
        save_fig(fig, "figure_08_heatmap_country_year")

    top = ranking.head(15).sort_values("structural_vulnerability_index")
    fig, ax = plt.subplots(figsize=(8, 5.4))
    sns.barplot(data=top, y="country_name", x="structural_vulnerability_index", color=PALETTE["informality"], ax=ax)
    ax.set_title("Figure 9. Country Ranking by Structural Vulnerability", loc="left", weight="bold")
    ax.set_xlabel("Index")
    ax.set_ylabel("")
    save_fig(fig, "figure_09_country_ranking")

    dist_vars = ["monetary_poverty", "labor_informality", "social_protection_coverage"]
    long = sample[dist_vars].melt(var_name="indicator", value_name="value").dropna()
    fig, ax = plt.subplots(figsize=(8, 5.0))
    sns.kdeplot(data=long, x="value", hue="indicator", fill=False, common_norm=False, linewidth=2, ax=ax)
    ax.set_title("Figure 11. Indicator Distributions", loc="left", weight="bold")
    ax.set_xlabel("Percent")
    ax.set_ylabel("Density")
    save_fig(fig, "figure_11_distribution")

    bol = sample.copy()
    bol["group"] = np.where(bol["iso3"] == "BOL", "Bolivia", "Latin America average")
    bol_year = bol.groupby(["group", "year"], as_index=False)[["monetary_poverty", "labor_informality", "social_protection_coverage"]].mean(numeric_only=True)
    fig, ax = plt.subplots(figsize=(8, 5.0))
    sns.lineplot(data=bol_year, x="year", y="monetary_poverty", hue="group", palette=[PALETTE["bolivia"], PALETTE["lac"]], linewidth=2.3, ax=ax)
    ax.set_title("Figure 12. Bolivia vs Latin America", loc="left", weight="bold")
    ax.set_xlabel("")
    ax.set_ylabel("Monetary poverty (%)")
    ax.legend(frameon=False)
    save_fig(fig, "figure_12_bolivia_vs_lac")



def write_figure_catalog() -> None:
    rows = [
        ("Figure 1", "figure_01_evolution_poverty", "Evolution of monetary poverty", "Tracks the regional average poverty headcount over time; use to identify shared macro and social-policy periods."),
        ("Figure 2", "figure_02_evolution_informality", "Evolution of labor informality", "Shows whether informality moved with or against poverty over the preferred panel window."),
        ("Figure 3", "figure_03_social_protection_coverage", "Social protection coverage", "Summarizes expansion or contraction in coverage, the central mitigating variable."),
        ("Figure 4", "figure_04_scatter_informality_poverty", "Informality vs poverty", "Displays the unconditional relationship motivating the panel regressions."),
        ("Figure 5", "figure_05_scatter_social_protection_poverty", "Social protection vs poverty", "Shows the raw association between protection coverage and poverty."),
        ("Figure 6", "figure_06_interaction_plot", "Informality-poverty gradient by protection coverage", "Visualizes the interaction hypothesis before formal fixed-effects estimation."),
        ("Figure 7", "figure_07_regional_map", "Regional vulnerability map", "Interactive HTML choropleth ranks country-year vulnerability; static PNG/PDF fallback is included for reports."),
        ("Figure 8", "figure_08_heatmap_country_year", "Country-year poverty heatmap", "Highlights panel coverage, persistence, and country-specific poverty episodes."),
        ("Figure 9", "figure_09_country_ranking", "Country vulnerability ranking", "Ranks latest country observations by the structural vulnerability index."),
        ("Figure 10", "figure_10_coefficient_plot", "Cluster-robust coefficient plot", "Summarizes preferred and robustness model estimates with confidence intervals."),
        ("Figure 11", "figure_11_distribution", "Indicator distributions", "Compares the empirical distributions of poverty, informality, and protection coverage."),
        ("Figure 12", "figure_12_bolivia_vs_lac", "Bolivia vs Latin America", "Contrasts Bolivia's poverty trajectory with the regional average."),
    ]
    catalog = pd.DataFrame(rows, columns=["figure", "file_stem", "caption", "interpretation"])
    catalog.to_csv(FIGURE_DIR / "figure_catalog.csv", index=False, encoding="utf-8-sig")
    (FIGURE_DIR / "figure_catalog.md").write_text(catalog.to_markdown(index=False), encoding="utf-8")


def dashboard_data(panel: pd.DataFrame) -> None:
    keep = [
        "iso3",
        "country_name",
        "region_lac",
        "year",
        "monetary_poverty",
        "extreme_poverty",
        "labor_informality",
        "social_protection_coverage",
        "gdp_per_capita",
        "female_labor_participation",
        "male_labor_participation",
        "unemployment",
        "gini",
        "social_expenditure",
        "structural_vulnerability_index",
    ]
    panel[keep].to_csv(DASHBOARD_DIR / "dashboard_panel.csv", index=False, encoding="utf-8-sig")


def main() -> int:
    panel = pd.read_csv(PANEL_PATH)
    sample = panel[panel["analysis_sample"] == 1].copy()
    tables = descriptive_tables(panel, sample)
    for name, table in tables.items():
        save_table(table, name)
    with pd.ExcelWriter(TABLE_DIR / "descriptive_tables.xlsx", engine="openpyxl") as writer:
        for name, table in tables.items():
            table.to_excel(writer, sheet_name=name[:31], index=False)
    figures(panel, sample, tables["table_3_country_ranking"])
    write_figure_catalog()
    dashboard_data(panel)
    print("descriptive_tables=5")
    print("figures_written=11_plus_interactive_map")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
