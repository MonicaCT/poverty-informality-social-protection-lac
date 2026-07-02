from pathlib import Path
import json
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "README.md",
    "DATA_INVENTORY.md",
    "AUDIT_REPORT.md",
    "FINAL_REPOSITORY_REVIEW.md",
    "docs/EMPIRICAL_STRATEGY.md",
    "docs/ECONOMETRIC_DIAGNOSTICS.md",
    "docs/DATA_LINEAGE.md",
    "docs/MODEL_LIMITATIONS.md",
    "data/metadata/CODEBOOK.md",
    "data/metadata/validation_report.md",
    "data/processed/lac_poverty_informality_social_protection_panel.csv",
    "outputs/models/model_results.csv",
    "outputs/models/econometric_diagnostics.csv",
    "outputs/models/gmm_diagnostics.md",
    "outputs/figures/figure_catalog.md",
    "dashboard/index.html",
    "dashboard/dashboard_preview.png",
    "policy_brief/policy_brief.pdf",
    "paper/paper_draft.md",
    "PUBLICATION_CHECKLIST.md",
    "assets/brand/repository-banner.png",
    "assets/brand/social-preview.png",
    "assets/screenshots/dashboard-overview.png",
    "docs/index.md",
]


def main() -> int:
    missing = [f for f in REQUIRED_FILES if not (ROOT / f).exists()]
    assert not missing, f"Missing required artifacts: {missing}"
    summary = json.loads((ROOT / "data" / "metadata" / "panel_build_summary.json").read_text(encoding="utf-8"))
    assert summary["complete_main_model_rows"] >= 100, "Main model sample is unexpectedly small"
    assert summary["complete_main_model_countries"] >= 10, "Too few countries in main model sample"
    results = pd.read_csv(ROOT / "outputs" / "models" / "model_results.csv")
    assert "se_type" in results.columns, "Model results must document standard-error type"
    assert results["se_type"].str.contains("cluster|robust", case=False, na=False).any(), "Robust or clustered SE missing"
    diagnostics = pd.read_csv(ROOT / "outputs" / "models" / "econometric_diagnostics.csv")
    required_metrics = {"max_vif", "breusch_pagan_heteroskedasticity", "panel_serial_correlation_pbgtest", "pesaran_cross_sectional_dependence", "hausman_fe_vs_re"}
    assert required_metrics.issubset(set(diagnostics["metric"])), "Econometric diagnostics incomplete"
    figure_catalog = pd.read_csv(ROOT / "outputs" / "figures" / "figure_catalog.csv")
    assert len(figure_catalog) >= 12, "Figure catalog must cover all required figures"
    dashboard = (ROOT / "dashboard" / "index.html").read_text(encoding="utf-8")
    assert "plotly.js" in dashboard.lower(), "Dashboard should embed Plotly for offline use"
    print("repository_output_tests_passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
