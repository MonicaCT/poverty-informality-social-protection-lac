from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "data" / "processed" / "lac_poverty_informality_social_protection_panel.csv"

def main() -> int:
    assert PANEL.exists(), f"Missing panel: {PANEL}"
    df = pd.read_csv(PANEL)
    assert not df.duplicated(["iso3", "year"]).any(), "Duplicate iso3-year rows found"
    assert df["iso3"].str.fullmatch(r"[A-Z]{3}").all(), "Invalid ISO3 code found"
    for col in ["monetary_poverty", "extreme_poverty", "labor_informality", "social_protection_coverage", "unemployment"]:
        s = df[col].dropna()
        assert ((s >= 0) & (s <= 100)).all(), f"Out-of-range percent variable: {col}"
    assert df.loc[df["analysis_sample"] == 1, "year"].between(2000, 2023).all(), "Analysis sample year outside 2000-2023"
    print("panel_integrity_tests_passed")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
