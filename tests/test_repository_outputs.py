from pathlib import Path
import json
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "README.md",
    "DATA_INVENTORY.md",
    "docs/DATA_LINEAGE.md",
    "docs/dashboard.md",
    "data/metadata/CODEBOOK.md",
    "data/metadata/validation_report.md",
    "data/processed/lac_poverty_informality_social_protection_panel.csv",
    "dashboard/dashboard.qmd",
    "dashboard/dashboard_panel.csv",
    "dashboard/index.html",
    "dashboard/dashboard_preview.png",
    "outputs/figures/figure_catalog.md",
    "outputs/tables/table_1_descriptive_statistics.csv",
    "outputs/tables/table_2_correlation_matrix.csv",
    "outputs/tables/table_3_country_ranking.csv",
    "outputs/tables/table_4_regional_summary.csv",
    "assets/brand/repository-banner.png",
    "assets/brand/social-preview.png",
    "assets/screenshots/dashboard-overview.png",
    "docs/index.md",
]


def main() -> int:
    missing = [f for f in REQUIRED_FILES if not (ROOT / f).exists()]
    assert not missing, f"Missing dashboard artifacts: {missing}"
    summary = json.loads((ROOT / "data" / "metadata" / "panel_build_summary.json").read_text(encoding="utf-8"))
    assert summary["rows"] >= 500, "Panel is unexpectedly small"
    assert summary["countries"] >= 20, "Too few countries in dashboard panel"
    figure_catalog = pd.read_csv(ROOT / "outputs" / "figures" / "figure_catalog.csv")
    assert len(figure_catalog) >= 10, "Figure catalog should cover dashboard figures"
    dashboard = (ROOT / "dashboard" / "index.html").read_text(encoding="utf-8")
    assert "Poverty, Informality" in dashboard, "Dashboard title missing"
    assert "plotly" in dashboard.lower(), "Dashboard should embed interactive chart assets"
    print("dashboard_output_tests_passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
