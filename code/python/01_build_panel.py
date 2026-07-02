"""Construct the harmonized LAC country-year panel.

This script uses the data inventory to select harmonized country-year outputs
from ASPIRE, Equity Lab, ILOSTAT, WDI, WB Gini, CEPAL, and SEDLAC. It does
not modify raw data. Outputs are written to data/processed and metadata/QC
folders for full reproducibility.
"""

from __future__ import annotations

import json
from functools import reduce
from pathlib import Path

import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PROCESSED = PROJECT_ROOT / "data" / "processed"
METADATA = PROJECT_ROOT / "data" / "metadata"
OUTPUTS = PROJECT_ROOT / "outputs"
LOGS = PROJECT_ROOT / "logs"

SOURCES = {
    "aspire": Path(r"D:\Papers Desarrollo_2026\Datos_papers_PART-I\1_WB - ASPIRE\output_country_year\aspire_wide_country_year.csv"),
    "equity_lab": Path(r"C:\Users\Asus\Documents\Datos_papers_PART-II\28_Equity Lab\output_country_year\equitylab_master_country_year.csv"),
    "ilostat": Path(r"C:\Users\Asus\Documents\Datos_papers_PART-II\33_ILOSTAT\output_country_year\ilostat_panel_country_year_wide.csv"),
    "wdi": Path(r"C:\Users\Asus\Documents\Datos_papers_PART-II\20_WDI\output_country_year\wdi_wide_country_year.csv"),
    "wdi_gdp_pop": Path(r"C:\Users\Asus\Documents\Datos_papers_PART-II\56_WDI_gdp\output_country_year\wdi_gdp_population_country_year.csv"),
    "wb_gini": Path(r"D:\Papers Desarrollo_2026\Datos_papers_PART-I\11_WB - GINI\output_country_year\panel_country_year_gini.csv"),
    "cepal": Path(r"C:\Users\Asus\Documents\Datos_papers_PART-II\24_CEPAL\output_country_year\cepal_master_country_year.csv"),
    "sedlac": Path(r"C:\Users\Asus\Documents\Datos_papers_PART-II\34_SEDLAC\output_country_year\sedlac_master_country_year.csv"),
}

LAC_COUNTRIES = {
    "ARG": "Argentina",
    "BOL": "Bolivia",
    "BRA": "Brazil",
    "CHL": "Chile",
    "COL": "Colombia",
    "CRI": "Costa Rica",
    "CUB": "Cuba",
    "DOM": "Dominican Republic",
    "ECU": "Ecuador",
    "SLV": "El Salvador",
    "GTM": "Guatemala",
    "HND": "Honduras",
    "HTI": "Haiti",
    "JAM": "Jamaica",
    "MEX": "Mexico",
    "NIC": "Nicaragua",
    "PAN": "Panama",
    "PRY": "Paraguay",
    "PER": "Peru",
    "URY": "Uruguay",
    "VEN": "Venezuela",
    "BLZ": "Belize",
    "GUY": "Guyana",
    "SUR": "Suriname",
    "BHS": "Bahamas",
    "BRB": "Barbados",
    "TTO": "Trinidad and Tobago",
}

REGION_MAP = {
    "BOL": "Andean",
    "COL": "Andean",
    "ECU": "Andean",
    "PER": "Andean",
    "VEN": "Andean",
    "ARG": "Mercosur",
    "BRA": "Mercosur",
    "PRY": "Mercosur",
    "URY": "Mercosur",
    "CRI": "Central America",
    "SLV": "Central America",
    "GTM": "Central America",
    "HND": "Central America",
    "NIC": "Central America",
    "PAN": "Central America",
    "BLZ": "Central America",
    "BHS": "Caribbean",
    "BRB": "Caribbean",
    "CUB": "Caribbean",
    "DOM": "Caribbean",
    "GUY": "Caribbean",
    "HTI": "Caribbean",
    "JAM": "Caribbean",
    "SUR": "Caribbean",
    "TTO": "Caribbean",
    "CHL": "Southern Cone",
    "MEX": "Mexico",
}


def ensure_dirs() -> None:
    for path in [PROCESSED, METADATA, OUTPUTS / "tables", OUTPUTS / "figures", OUTPUTS / "models", LOGS]:
        path.mkdir(parents=True, exist_ok=True)


def read_source(name: str) -> pd.DataFrame:
    path = SOURCES[name]
    if not path.exists():
        raise FileNotFoundError(f"Missing source {name}: {path}")
    df = pd.read_csv(path, low_memory=False)
    df.columns = [str(c).strip() for c in df.columns]
    return df


def first_existing(df: pd.DataFrame, candidates: list[str]) -> str | None:
    for col in candidates:
        if col in df.columns:
            return col
    return None


def select_rename(df: pd.DataFrame, mapping: dict[str, list[str] | str], source: str) -> pd.DataFrame:
    selected = {}
    for out, candidates in mapping.items():
        if isinstance(candidates, str):
            candidates = [candidates]
        col = first_existing(df, candidates)
        if col is not None:
            selected[out] = df[col]
    out = pd.DataFrame(selected)
    if "iso3" not in out.columns:
        raise ValueError(f"{source} did not provide an ISO3 column")
    if "year" not in out.columns:
        raise ValueError(f"{source} did not provide a year column")
    out["iso3"] = out["iso3"].astype(str).str.upper().str.strip()
    out["year"] = pd.to_numeric(out["year"], errors="coerce").astype("Int64")
    out = out.dropna(subset=["iso3", "year"]).copy()
    out["year"] = out["year"].astype(int)
    value_cols = [c for c in out.columns if c not in {"iso3", "year", "country_name"}]
    for col in value_cols:
        out[col] = pd.to_numeric(out[col], errors="coerce")
    out = out.drop_duplicates(["iso3", "year"], keep="last")
    out["source_" + source] = 1
    return out


def coalesce(df: pd.DataFrame, cols: list[str]) -> pd.Series:
    existing = [c for c in cols if c in df.columns]
    if not existing:
        return pd.Series(np.nan, index=df.index)
    return df[existing].bfill(axis=1).iloc[:, 0]


def zscore(series: pd.Series) -> pd.Series:
    valid = pd.to_numeric(series, errors="coerce")
    sd = valid.std(skipna=True)
    if pd.isna(sd) or sd == 0:
        return pd.Series(np.nan, index=series.index)
    return (valid - valid.mean(skipna=True)) / sd


def build_source_frames() -> tuple[list[pd.DataFrame], list[dict[str, str]]]:
    provenance = []
    frames = []

    equity = read_source("equity_lab")
    frames.append(
        select_rename(
            equity,
            {
                "country_name": ["country"],
                "iso3": ["iso3c"],
                "year": ["year"],
                "poverty_extreme_equity": ["data_1_poverty_3_0_2021_ppp_by_country"],
                "poverty_moderate_equity": ["data_1_poverty_8_30_2021_ppp_by_country", "data_1_poverty_4_20_2021_ppp_by_country"],
                "poverty_gap_equity": ["data_2_x_poverty_gap"],
                "informality_productivity_equity": ["t_i_i_informality_productivity_definition_total"],
                "informality_social_protection_equity": ["t_i_i_informality_social_protection_definition_total"],
                "female_lfp_equity": ["t_mli_labor_force_participation_rate_sex_female"],
                "male_lfp_equity": ["t_mli_labor_force_participation_rate_sex_male"],
                "lfp_total_equity": ["t_mli_labor_force_participation_rate_total"],
                "unemployment_equity": ["t_mli_unemployment_rate_total"],
                "youth_unemployment_equity": ["t_mli_youth_unemployment_rate_total"],
                "labor_income_gini_equity": ["t_li_wd_labor_income_gini_total"],
            },
            "equity_lab",
        )
    )
    provenance.append({"source": "equity_lab", "path": str(SOURCES["equity_lab"]), "role": "poverty, labor informality, gender labor indicators"})

    ilostat = read_source("ilostat")
    frames.append(
        select_rename(
            ilostat,
            {
                "country_name": ["country_name"],
                "iso3": ["iso3c"],
                "year": ["year"],
                "labor_force_participation_ilostat": ["labor_force_participation"],
                "employment_to_population_ilostat": ["employment_to_population"],
                "unemployment_ilostat": ["unemployment_rate", "unemployment_rate_b"],
                "informality_ilostat": ["informal_employment_rate", "informal_employment_5category_rate", "informal_sector_employment_rate"],
                "working_poverty_ilostat": ["working_poverty_rate"],
            },
            "ilostat",
        )
    )
    provenance.append({"source": "ilostat", "path": str(SOURCES["ilostat"]), "role": "labor market and informality indicators"})

    wdi = read_source("wdi")
    frames.append(
        select_rename(
            wdi,
            {
                "country_name": ["country_name"],
                "iso3": ["iso3c"],
                "year": ["year"],
                "gdp_per_capita_constant": ["wdi_ny_gdp_pcap_kd"],
                "gdp_per_capita_ppp": ["wdi_ny_gdp_pcap_pp_kd"],
                "gdp_per_capita_growth": ["wdi_ny_gdp_pcap_kd_zg"],
                "poverty_extreme_wdi": ["wdi_si_pov_dday"],
                "poverty_moderate_wdi": ["wdi_si_pov_umic"],
                "poverty_gap_wdi": ["wdi_si_pov_umic_gp"],
                "social_protection_coverage_wdi": ["wdi_per_allsp_cov_pop_tot"],
                "population_growth": ["wdi_sp_pop_grow"],
            },
            "wdi",
        )
    )
    provenance.append({"source": "wdi", "path": str(SOURCES["wdi"]), "role": "poverty benchmarks and macro controls"})

    wdi_gdp = read_source("wdi_gdp_pop")
    frames.append(
        select_rename(
            wdi_gdp,
            {
                "country_name": ["country"],
                "iso3": ["iso3c"],
                "year": ["year"],
                "population": ["SP.POP.TOTL"],
                "gdp_per_capita_constant_alt": ["NY.GDP.PCAP.KD"],
            },
            "wdi_gdp_pop",
        )
    )
    provenance.append({"source": "wdi_gdp_pop", "path": str(SOURCES["wdi_gdp_pop"]), "role": "GDP per capita and population controls"})

    aspire = read_source("aspire")
    frames.append(
        select_rename(
            aspire,
            {
                "country_name": ["country"],
                "iso3": ["iso3c"],
                "year": ["year"],
                "social_protection_coverage_aspire": ["per_allsp_cov_pop_tot", "per_allsp_cov_ep_tot"],
                "social_protection_adequacy_aspire": ["per_allsp_adq_pop_tot", "per_allsp_adq_ep_tot"],
                "social_assistance_coverage_aspire": ["per_sa_allsa_cov_pop_tot"],
                "social_insurance_coverage_aspire": ["per_si_allsi_cov_pop_tot"],
                "cash_transfer_coverage_aspire": ["per_sa_ct_cov_pop_tot"],
                "pension_coverage_aspire": ["per_si_cp_cov_pop_tot"],
                "public_transfer_benefit_q1_aspire": ["per_allsp_ben_q1_tot", "per_sa_allsa_ben_q1_tot"],
            },
            "aspire",
        )
    )
    provenance.append({"source": "aspire", "path": str(SOURCES["aspire"]), "role": "social protection coverage, adequacy, and benefit incidence"})

    gini = read_source("wb_gini")
    frames.append(
        select_rename(
            gini,
            {
                "country_name": ["country_name"],
                "iso3": ["iso3c"],
                "year": ["year"],
                "gini_wb": ["gini"],
            },
            "wb_gini",
        )
    )
    provenance.append({"source": "wb_gini", "path": str(SOURCES["wb_gini"]), "role": "Gini coefficient"})

    cepal = read_source("cepal")
    frames.append(
        select_rename(
            cepal,
            {
                "country_name": ["country"],
                "iso3": ["iso3c"],
                "year": ["year"],
                "social_expenditure": [
                    "cepal_gasto_publico_gobierno_general_proteccion_social",
                    "cepal_gasto_publico_gobierno_central_proteccion_social",
                    "cepal_gasto_publico_sector_publico_no_financiero_proteccion_social",
                ],
                "education_expenditure": [
                    "cepal_gasto_publico_gobierno_general_educacion",
                    "cepal_gasto_publico_gobierno_central_educacion",
                    "cepal_gasto_publico_sector_publico_no_financiero_educacion",
                ],
                "health_expenditure": [
                    "cepal_gasto_publico_gobierno_general_salud",
                    "cepal_gasto_publico_gobierno_central_salud",
                    "cepal_gasto_publico_sector_publico_no_financiero_salud",
                ],
                "government_expenditure_total": [
                    "cepal_gasto_publico_gobierno_general_erogaciones_totales",
                    "cepal_gasto_publico_gobierno_central_erogaciones_totales",
                ],
            },
            "cepal",
        )
    )
    provenance.append({"source": "cepal", "path": str(SOURCES["cepal"]), "role": "social, education, health, and total government expenditure"})

    sedlac = read_source("sedlac")
    sedlac_income_col = first_existing(sedlac, [
        "incomes_deciles_pci_gba_mean",
        "incomes_deciles_pci_urban_mean",
        "incomes_deciles_pci_dgec_with_non_labor_income_mean",
        "incomes_deciles_pci_dgec_without_non_labor_income_mean",
    ])
    sedlac_map = {"country_name": ["country"], "iso3": ["iso3c"], "year": ["year"]}
    if sedlac_income_col:
        sedlac_map["sedlac_income_mean"] = [sedlac_income_col]
    frames.append(select_rename(sedlac, sedlac_map, "sedlac"))
    provenance.append({"source": "sedlac", "path": str(SOURCES["sedlac"]), "role": "income distribution extension and poverty-source audit"})

    return frames, provenance


def construct_panel(frames: list[pd.DataFrame]) -> pd.DataFrame:
    panel = reduce(lambda left, right: pd.merge(left, right, on=["iso3", "year"], how="outer", suffixes=("", "_dup")), frames)
    country_cols = [c for c in panel.columns if c.startswith("country_name")]
    panel["country_name"] = coalesce(panel, country_cols)
    duplicate_cols = [c for c in panel.columns if c.endswith("_dup")]
    panel = panel.drop(columns=duplicate_cols)
    panel = panel[panel["iso3"].isin(LAC_COUNTRIES)].copy()
    panel["country_name"] = panel["iso3"].map(LAC_COUNTRIES).fillna(panel["country_name"])
    panel["region_lac"] = panel["iso3"].map(REGION_MAP).fillna("Other LAC")
    panel["bolivia"] = (panel["iso3"] == "BOL").astype(int)
    panel["analysis_sample"] = panel["year"].between(2000, 2023).astype(int)

    panel["monetary_poverty"] = coalesce(panel, ["poverty_moderate_wdi", "poverty_moderate_equity"])
    panel["extreme_poverty"] = coalesce(panel, ["poverty_extreme_wdi", "poverty_extreme_equity"])
    panel["poverty_gap"] = coalesce(panel, ["poverty_gap_wdi"])
    panel["labor_informality"] = coalesce(panel, ["informality_ilostat", "informality_social_protection_equity", "informality_productivity_equity"])
    panel["social_protection_coverage"] = coalesce(panel, ["social_protection_coverage_aspire", "social_protection_coverage_wdi"])
    panel["female_labor_participation"] = coalesce(panel, ["female_lfp_equity"])
    panel["male_labor_participation"] = coalesce(panel, ["male_lfp_equity"])
    panel["labor_force_participation"] = coalesce(panel, ["lfp_total_equity", "labor_force_participation_ilostat"])
    panel["unemployment"] = coalesce(panel, ["unemployment_equity", "unemployment_ilostat"])
    panel["youth_unemployment"] = coalesce(panel, ["youth_unemployment_equity"])
    panel["employment"] = coalesce(panel, ["employment_to_population_ilostat"])
    panel["gdp_per_capita"] = coalesce(panel, ["gdp_per_capita_constant", "gdp_per_capita_constant_alt", "gdp_per_capita_ppp"])
    panel["log_gdp_per_capita"] = np.log(panel["gdp_per_capita"].where(panel["gdp_per_capita"] > 0))
    panel["gini"] = coalesce(panel, ["gini_wb", "labor_income_gini_equity"])
    panel["population_total"] = coalesce(panel, ["population"])

    panel = panel.sort_values(["iso3", "year"]).reset_index(drop=True)
    panel["labor_informality_lag1"] = panel.groupby("iso3")["labor_informality"].shift(1)
    panel["social_protection_lag1"] = panel.groupby("iso3")["social_protection_coverage"].shift(1)
    panel["poverty_lag1"] = panel.groupby("iso3")["monetary_poverty"].shift(1)
    panel["informality_x_social_protection"] = panel["labor_informality"] * panel["social_protection_coverage"] / 100

    vulnerability_inputs = {
        "poverty": panel["monetary_poverty"],
        "informality": panel["labor_informality"],
        "unemployment": panel["unemployment"],
        "gini": panel["gini"],
        "low_social_protection": -panel["social_protection_coverage"],
        "low_gdp": -panel["log_gdp_per_capita"],
    }
    z = pd.DataFrame({name: zscore(value) for name, value in vulnerability_inputs.items()})
    panel["structural_vulnerability_index"] = z.mean(axis=1, skipna=True)
    return panel


def build_data_dictionary(panel: pd.DataFrame) -> pd.DataFrame:
    rows = [
        ("iso3", "ISO3 country code", "standardized", "code"),
        ("country_name", "Country name", "standardized", "text"),
        ("year", "Calendar year", "standardized", "year"),
        ("region_lac", "Analytical LAC subregion", "constructed", "category"),
        ("bolivia", "Indicator equal to 1 for Bolivia", "constructed", "0/1"),
        ("analysis_sample", "Preferred estimation window, 2000-2023", "constructed", "0/1"),
        ("monetary_poverty", "Poverty headcount, preferred moderate line", "WDI upper-middle-income line, fallback Equity Lab 2021 PPP", "percent"),
        ("extreme_poverty", "Extreme poverty headcount", "WDI $2.15/day, fallback Equity Lab $3.00/day 2021 PPP", "percent"),
        ("poverty_gap", "Poverty gap", "WDI upper-middle-income poverty gap", "percent"),
        ("labor_informality", "Labor informality rate", "ILOSTAT informal employment, fallback Equity Lab social-protection/productivity definitions", "percent"),
        ("social_protection_coverage", "Population covered by social protection", "ASPIRE all social protection coverage, fallback WDI", "percent"),
        ("female_labor_participation", "Female labor force participation", "Equity Lab", "percent"),
        ("male_labor_participation", "Male labor force participation", "Equity Lab", "percent"),
        ("labor_force_participation", "Total labor force participation", "Equity Lab, fallback ILOSTAT", "percent"),
        ("unemployment", "Unemployment rate", "Equity Lab, fallback ILOSTAT", "percent"),
        ("youth_unemployment", "Youth unemployment rate", "Equity Lab", "percent"),
        ("employment", "Employment-to-population ratio", "ILOSTAT", "percent"),
        ("gdp_per_capita", "GDP per capita, constant local/international benchmark", "WDI", "currency index / constant dollars"),
        ("log_gdp_per_capita", "Natural log GDP per capita", "constructed from WDI", "log"),
        ("gdp_per_capita_growth", "GDP per capita growth", "WDI", "percent"),
        ("population_total", "Total population", "WDI GDP/population extract", "persons"),
        ("population_growth", "Population growth", "WDI", "percent"),
        ("gini", "Gini coefficient", "World Bank Gini, fallback Equity Lab labor-income Gini", "index"),
        ("social_expenditure", "Public expenditure on social protection", "CEPAL", "percent of GDP or source unit"),
        ("education_expenditure", "Public expenditure on education", "CEPAL", "percent of GDP or source unit"),
        ("health_expenditure", "Public expenditure on health", "CEPAL", "percent of GDP or source unit"),
        ("government_expenditure_total", "Total public expenditure", "CEPAL", "percent of GDP or source unit"),
        ("social_protection_adequacy_aspire", "Adequacy of social protection benefits", "ASPIRE", "percent"),
        ("social_assistance_coverage_aspire", "Social assistance coverage", "ASPIRE", "percent"),
        ("social_insurance_coverage_aspire", "Social insurance coverage", "ASPIRE", "percent"),
        ("cash_transfer_coverage_aspire", "Cash transfer coverage", "ASPIRE", "percent"),
        ("pension_coverage_aspire", "Pension coverage", "ASPIRE", "percent"),
        ("public_transfer_benefit_q1_aspire", "Benefit incidence/level for poorest quintile", "ASPIRE", "percent or source unit"),
        ("labor_informality_lag1", "One-year lag of labor informality", "constructed", "percent"),
        ("social_protection_lag1", "One-year lag of social protection coverage", "constructed", "percent"),
        ("poverty_lag1", "One-year lag of monetary poverty", "constructed", "percent"),
        ("informality_x_social_protection", "Interaction: informality times social protection coverage divided by 100", "constructed", "percentage-point interaction"),
        ("structural_vulnerability_index", "Standardized vulnerability index", "mean of z-scored poverty, informality, unemployment, Gini, low social protection, low GDP", "z-score"),
    ]
    out = pd.DataFrame(rows, columns=["variable", "description", "source_or_construction", "unit"])
    out["available_in_panel"] = out["variable"].isin(panel.columns)
    out["non_missing_obs"] = out["variable"].map(lambda c: int(panel[c].notna().sum()) if c in panel.columns else 0)
    return out


def quality_control(panel: pd.DataFrame) -> dict[str, pd.DataFrame | dict[str, int | float | str]]:
    duplicate_rows = panel[panel.duplicated(["iso3", "year"], keep=False)].copy()
    percent_cols = [
        "monetary_poverty",
        "extreme_poverty",
        "poverty_gap",
        "labor_informality",
        "social_protection_coverage",
        "female_labor_participation",
        "male_labor_participation",
        "labor_force_participation",
        "unemployment",
        "youth_unemployment",
        "employment",
    ]
    impossible = []
    for col in percent_cols:
        if col in panel.columns:
            bad = panel[panel[col].notna() & ((panel[col] < 0) | (panel[col] > 100))][["iso3", "country_name", "year", col]].copy()
            bad["variable"] = col
            bad = bad.rename(columns={col: "value"})
            impossible.append(bad[["iso3", "country_name", "year", "variable", "value"]])
    impossible_df = pd.concat(impossible, ignore_index=True) if impossible else pd.DataFrame(columns=["iso3", "country_name", "year", "variable", "value"])
    missing = (
        panel.isna().mean().mul(100).round(2).reset_index().rename(columns={"index": "variable", 0: "missing_pct"})
    )
    coverage_country = (
        panel.groupby(["iso3", "country_name", "region_lac"], dropna=False)
        .agg(
            first_year=("year", "min"),
            last_year=("year", "max"),
            n_years=("year", "nunique"),
            poverty_obs=("monetary_poverty", lambda x: int(x.notna().sum())),
            informality_obs=("labor_informality", lambda x: int(x.notna().sum())),
            social_protection_obs=("social_protection_coverage", lambda x: int(x.notna().sum())),
        )
        .reset_index()
    )
    coverage_year = (
        panel.groupby("year")
        .agg(
            countries=("iso3", "nunique"),
            poverty_obs=("monetary_poverty", lambda x: int(x.notna().sum())),
            informality_obs=("labor_informality", lambda x: int(x.notna().sum())),
            social_protection_obs=("social_protection_coverage", lambda x: int(x.notna().sum())),
        )
        .reset_index()
    )
    main_model_vars = [
        "monetary_poverty",
        "labor_informality",
        "social_protection_coverage",
        "log_gdp_per_capita",
        "gini",
        "unemployment",
    ]
    main_model_sample = panel.loc[panel["analysis_sample"].eq(1), ["iso3", "year"] + main_model_vars].dropna()
    summary = {
        "rows": int(len(panel)),
        "countries": int(panel["iso3"].nunique()),
        "years": f"{int(panel['year'].min())}-{int(panel['year'].max())}",
        "duplicate_country_year_rows": int(len(duplicate_rows)),
        "impossible_percent_values": int(len(impossible_df)),
        "analysis_sample_rows": int(panel["analysis_sample"].sum()),
        "complete_main_model_rows": int(main_model_sample.shape[0]),
        "complete_main_model_countries": int(main_model_sample["iso3"].nunique()),
        "complete_main_model_years": f"{int(main_model_sample['year'].min())}-{int(main_model_sample['year'].max())}" if not main_model_sample.empty else "NA",
    }
    return {
        "summary": summary,
        "duplicates": duplicate_rows,
        "impossible_values": impossible_df,
        "missing": missing,
        "coverage_country": coverage_country,
        "coverage_year": coverage_year,
    }


def write_validation_report(qc: dict[str, pd.DataFrame | dict[str, int | float | str]]) -> None:
    summary = qc["summary"]
    missing = qc["missing"].sort_values("missing_pct", ascending=False).head(25)
    coverage = qc["coverage_country"].sort_values("poverty_obs", ascending=False)
    lines = [
        "# Data Validation Report",
        "",
        "## Summary",
        "",
    ]
    for key, value in summary.items():
        lines.append(f"- {key}: {value}")
    lines.extend([
        "",
        "## Highest Missingness Variables",
        "",
        missing.to_markdown(index=False),
        "",
        "## Country Coverage",
        "",
        coverage.to_markdown(index=False),
        "",
        "## Notes",
        "",
        "- Impossible percentage values are written to `data/metadata/qc_impossible_values.csv`.",
        "- The preferred empirical sample is `analysis_sample == 1`, covering 2000-2023.",
        "- Missingness reflects source coverage, not only data quality; social protection and informality series are the binding constraints.",
        "",
    ])
    (METADATA / "validation_report.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    ensure_dirs()
    frames, provenance = build_source_frames()
    panel = construct_panel(frames)
    dictionary = build_data_dictionary(panel)
    qc = quality_control(panel)

    panel.to_csv(PROCESSED / "lac_poverty_informality_social_protection_panel.csv", index=False, encoding="utf-8-sig")
    panel.to_parquet(PROCESSED / "lac_poverty_informality_social_protection_panel.parquet", index=False)
    dictionary.to_csv(METADATA / "data_dictionary.csv", index=False, encoding="utf-8-sig")
    pd.DataFrame(provenance).to_csv(METADATA / "source_provenance.csv", index=False, encoding="utf-8-sig")
    qc["missing"].to_csv(METADATA / "qc_missing_values.csv", index=False, encoding="utf-8-sig")
    qc["coverage_country"].to_csv(METADATA / "qc_country_coverage.csv", index=False, encoding="utf-8-sig")
    qc["coverage_year"].to_csv(METADATA / "qc_year_coverage.csv", index=False, encoding="utf-8-sig")
    qc["impossible_values"].to_csv(METADATA / "qc_impossible_values.csv", index=False, encoding="utf-8-sig")
    qc["duplicates"].to_csv(METADATA / "qc_duplicate_country_year.csv", index=False, encoding="utf-8-sig")
    (METADATA / "panel_build_summary.json").write_text(json.dumps(qc["summary"], indent=2), encoding="utf-8")
    write_validation_report(qc)
    print(json.dumps(qc["summary"], indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


