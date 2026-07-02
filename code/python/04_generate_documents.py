"""Regenerate final narrative artifacts that do not require Quarto."""

from __future__ import annotations

import json
from pathlib import Path
from textwrap import wrap

import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.backends.backend_pdf import PdfPages


PROJECT_ROOT = Path(__file__).resolve().parents[2]
POLICY_DIR = PROJECT_ROOT / "policy_brief"
POLICY_DIR.mkdir(parents=True, exist_ok=True)


def pick_coef(models: pd.DataFrame, model: str, term: str, col: str) -> float:
    row = models[(models["model"] == model) & (models["term"] == term)]
    return float(row[col].iloc[0]) if len(row) else float("nan")


def pick_metric(diag: pd.DataFrame, metric: str, col: str = "value") -> float:
    row = diag[diag["metric"] == metric]
    return float(row[col].iloc[0]) if len(row) else float("nan")


def fmt(value: float, digits: int = 3) -> str:
    return "NA" if pd.isna(value) else f"{value:.{digits}f}"


def generate_policy_pdf() -> None:
    summary = json.loads((PROJECT_ROOT / "data" / "metadata" / "panel_build_summary.json").read_text(encoding="utf-8"))
    models = pd.read_csv(PROJECT_ROOT / "outputs" / "models" / "model_results.csv")
    diag = pd.read_csv(PROJECT_ROOT / "outputs" / "models" / "econometric_diagnostics.csv")
    twfe_sp = pick_coef(models, "Model 4 - Two-way Fixed Effects", "social_protection_coverage", "estimate")
    twfe_sp_p = pick_coef(models, "Model 4 - Two-way Fixed Effects", "social_protection_coverage", "p.value")
    twfe_inf = pick_coef(models, "Model 4 - Two-way Fixed Effects", "labor_informality", "estimate")
    twfe_inf_p = pick_coef(models, "Model 4 - Two-way Fixed Effects", "labor_informality", "p.value")
    interaction = pick_coef(models, "Model 8 - Informality x Social Protection", "labor_informality:social_protection_coverage", "estimate")
    interaction_p = pick_coef(models, "Model 8 - Informality x Social Protection", "labor_informality:social_protection_coverage", "p.value")
    pages = [
        ("Labor Informality, Social Protection, and Poverty", [
            "Policy brief for internal research portfolio review.",
            "Main message: social protection coverage is negatively associated with poverty, but the informality mitigation hypothesis remains suggestive rather than decisive.",
            "The results are associational and should be interpreted as evidence for prioritization, not as causal program-impact estimates.",
        ]),
        ("Evidence Base", [
            "Recursive inventory: 3,411 structured files, 323,659 variables, 541 documentation/script assets, and 96 source collections.",
            f"Panel: {summary['rows']:,} country-year rows across {summary['countries']} LAC countries, years {summary['years']}.",
            f"Preferred complete estimation sample: {summary['complete_main_model_rows']} observations, {summary['complete_main_model_countries']} country clusters, years {summary['complete_main_model_years']}.",
            "Sources: ASPIRE, Equity Lab, ILOSTAT, WDI, World Bank Gini, CEPAL, and SEDLAC.",
        ]),
        ("Audited Econometric Findings", [
            f"TWFE social protection coefficient: {fmt(twfe_sp)}, p={fmt(twfe_sp_p)}. Higher coverage is associated with lower poverty.",
            f"TWFE informality coefficient: {fmt(twfe_inf)}, p={fmt(twfe_inf_p)}. The sign is positive but not robustly significant after country clustering.",
            f"Interaction coefficient: {fmt(interaction, 4)}, p={fmt(interaction_p)}. The sign is consistent with mitigation but imprecise.",
            "Fixed effects are preferred to random effects by the Hausman test.",
        ]),
        ("Diagnostics And Credibility", [
            f"Heteroskedasticity p-value: {fmt(pick_metric(diag, 'breusch_pagan_heteroskedasticity', 'p_value'), 4)}.",
            f"Panel serial correlation p-value: {fmt(pick_metric(diag, 'panel_serial_correlation_pbgtest', 'p_value'), 4)}.",
            f"Cross-sectional dependence p-value: {fmt(pick_metric(diag, 'pesaran_cross_sectional_dependence', 'p_value'), 4)}.",
            "These diagnostics justify robust, country-clustered inference and a cautious interpretation of p-values.",
            "GMM models are retained as robustness checks only due to singular weighting-matrix warnings.",
        ]),
        ("Policy Implications", [
            "1. Expand social protection to informal workers, especially those outside contributory systems.",
            "2. Improve benefit adequacy, delivery reliability, and program interoperability.",
            "3. Link transfers and pensions to labor-market services when appropriate.",
            "4. Use structural vulnerability rankings to identify countries requiring deeper diagnostics.",
            "5. Prioritize Bolivia microdata harmonization as the next validation stage.",
        ]),
        ("Next Research Stage", [
            "Move beyond aggregate associations by exploiting policy rollout timing, eligibility rules, administrative data, or household microdata.",
            "Validate the Bolivia profile using survey weights, household composition, labor status, and transfer receipt.",
            "Document source-specific definitions for poverty, informality, and social protection before publication.",
        ]),
    ]
    with PdfPages(POLICY_DIR / "policy_brief.pdf") as pdf:
        for title, lines in pages:
            fig = plt.figure(figsize=(8.27, 11.69))
            ax = fig.add_axes([0, 0, 1, 1])
            ax.axis("off")
            ax.add_patch(plt.Rectangle((0, 0.93), 1, 0.07, color="#005A8B", transform=ax.transAxes))
            ax.text(0.06, 0.955, "Poverty, Informality, and Social Protection in LAC", color="white", fontsize=13, weight="bold", va="center")
            ax.text(0.06, 0.875, title, fontsize=22, weight="bold", color="#1f2933", va="top")
            y = 0.80
            for line in lines:
                for part in wrap(line, width=88):
                    ax.text(0.08, y, part, fontsize=12.5, color="#243b53", va="top")
                    y -= 0.035
                y -= 0.025
            ax.text(0.06, 0.055, "Generated reproducibly from code/python/04_generate_documents.py", fontsize=9.5, color="#66788a")
            pdf.savefig(fig, bbox_inches="tight")
            plt.close(fig)


def main() -> int:
    generate_policy_pdf()
    print("generated_policy_brief_pdf")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
