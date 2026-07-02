"""Build the standalone internal dashboard.

The dashboard is intentionally self-contained: Plotly.js and the panel data are
embedded in the HTML so it can be opened locally without a web server or network.
"""

from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from plotly.offline.offline import get_plotlyjs


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PANEL_PATH = PROJECT_ROOT / "data" / "processed" / "lac_poverty_informality_social_protection_panel.csv"
DASHBOARD_DIR = PROJECT_ROOT / "dashboard"
DASHBOARD_DIR.mkdir(parents=True, exist_ok=True)

DASHBOARD_COLUMNS = [
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


def load_data() -> pd.DataFrame:
    panel = pd.read_csv(PANEL_PATH)
    dash = panel[DASHBOARD_COLUMNS].copy()
    dash = dash[dash["year"].between(2000, 2023)]
    dash.to_csv(DASHBOARD_DIR / "dashboard_panel.csv", index=False, encoding="utf-8-sig")
    return dash


def build_preview(panel: pd.DataFrame) -> None:
    latest = panel.dropna(subset=["structural_vulnerability_index"]).sort_values("year").groupby("country_name").tail(1)
    top = latest.sort_values("structural_vulnerability_index", ascending=False).head(8).sort_values("structural_vulnerability_index")
    fig = plt.figure(figsize=(12, 7), facecolor="#f7f9fb")
    gs = fig.add_gridspec(2, 2, height_ratios=[0.8, 1.2])
    ax0 = fig.add_subplot(gs[0, :])
    ax0.axis("off")
    ax0.text(0.0, 0.80, "Poverty, Informality, and Social Protection in LAC", fontsize=22, weight="bold", color="#123047")
    ax0.text(0.0, 0.42, "Internal dashboard preview: vulnerability, poverty, informality, protection, GDP, and gender labor indicators", fontsize=12, color="#486581")
    kpis = [
        ("Countries", panel["iso3"].nunique()),
        ("Years", f"{panel['year'].min()}-{panel['year'].max()}"),
        ("Country-year rows", f"{len(panel):,}"),
        ("Latest high-risk countries", len(top)),
    ]
    for i, (label, value) in enumerate(kpis):
        x = 0.02 + i * 0.24
        ax0.add_patch(plt.Rectangle((x, 0.02), 0.20, 0.25, color="white", ec="#d9e2ec", transform=ax0.transAxes))
        ax0.text(x + 0.015, 0.18, label, fontsize=9, color="#627d98", transform=ax0.transAxes)
        ax0.text(x + 0.015, 0.07, str(value), fontsize=15, weight="bold", color="#102a43", transform=ax0.transAxes)
    ax1 = fig.add_subplot(gs[1, 0])
    ax1.barh(top["country_name"], top["structural_vulnerability_index"], color="#005A8B")
    ax1.set_title("Latest Structural Vulnerability Ranking", loc="left", weight="bold")
    ax1.set_xlabel("Index")
    ax1.grid(axis="x", alpha=0.25)
    ax2 = fig.add_subplot(gs[1, 1])
    bol = panel[panel["iso3"].eq("BOL")].sort_values("year")
    ax2.plot(bol["year"], bol["monetary_poverty"], label="Poverty", color="#005A8B", linewidth=2)
    ax2.plot(bol["year"], bol["labor_informality"], label="Informality", color="#F58518", linewidth=2)
    ax2.plot(bol["year"], bol["social_protection_coverage"], label="Social protection", color="#54A24B", linewidth=2)
    ax2.set_title("Bolivia Profile", loc="left", weight="bold")
    ax2.set_ylabel("Percent")
    ax2.legend(frameon=False)
    ax2.grid(alpha=0.25)
    fig.tight_layout()
    fig.savefig(DASHBOARD_DIR / "dashboard_preview.png", dpi=300, bbox_inches="tight")
    plt.close(fig)


def build_html(panel: pd.DataFrame) -> None:
    records = panel.where(pd.notnull(panel), None).to_dict(orient="records")
    plotly_js = get_plotlyjs()
    html = f"""
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>IDB-Style Poverty, Informality, and Social Protection Dashboard</title>
<style>
:root {{ --idb:#005A8B; --ink:#102a43; --muted:#627d98; --line:#d9e2ec; --bg:#f6f8fb; --panel:#ffffff; --accent:#F58518; --green:#54A24B; }}
* {{ box-sizing:border-box; }}
body {{ margin:0; font-family: Inter, Segoe UI, Arial, sans-serif; color:var(--ink); background:var(--bg); }}
.app {{ min-height:100vh; display:grid; grid-template-columns:280px 1fr; }}
aside {{ background:#0b2f44; color:white; padding:24px 20px; position:sticky; top:0; height:100vh; }}
aside h1 {{ font-size:20px; line-height:1.18; margin:0 0 18px; }}
aside .small {{ color:#b6d4e2; font-size:12px; line-height:1.5; }}
nav {{ display:flex; flex-direction:column; gap:8px; margin:24px 0; }}
nav a {{ color:#dbeef7; text-decoration:none; padding:8px 10px; border-radius:6px; font-size:14px; }}
nav a:hover {{ background:rgba(255,255,255,.10); }}
main {{ padding:24px 28px 42px; }}
.topbar {{ display:flex; justify-content:space-between; gap:16px; align-items:flex-start; margin-bottom:18px; }}
.title h2 {{ margin:0 0 6px; font-size:26px; }}
.title p {{ margin:0; color:var(--muted); max-width:900px; }}
.controls {{ display:flex; flex-wrap:wrap; gap:12px; align-items:center; background:var(--panel); border:1px solid var(--line); padding:12px; border-radius:8px; }}
label {{ font-size:12px; color:var(--muted); display:flex; flex-direction:column; gap:4px; }}
select,input {{ min-width:160px; padding:8px 10px; border:1px solid #bcccdc; border-radius:6px; background:white; color:var(--ink); }}
.kpis {{ display:grid; grid-template-columns:repeat(4,minmax(150px,1fr)); gap:12px; margin:18px 0; }}
.kpi {{ background:var(--panel); border:1px solid var(--line); border-left:4px solid var(--idb); border-radius:8px; padding:14px; }}
.kpi .label {{ font-size:12px; color:var(--muted); }}
.kpi .value {{ font-size:26px; font-weight:750; margin-top:6px; }}
.grid {{ display:grid; grid-template-columns:1fr 1fr; gap:16px; }}
.panel {{ background:var(--panel); border:1px solid var(--line); border-radius:8px; padding:12px; min-height:430px; }}
.panel.wide {{ grid-column:1 / -1; }}
.note {{ color:var(--muted); font-size:12px; line-height:1.5; margin-top:14px; }}
.summary {{ background:#e6f2f8; border:1px solid #b8dce9; border-radius:8px; padding:12px 14px; line-height:1.5; margin-bottom:16px; }}
@media(max-width:1050px) {{ .app {{ grid-template-columns:1fr; }} aside {{ position:relative; height:auto; }} .grid,.kpis {{ grid-template-columns:1fr; }} .topbar {{ flex-direction:column; }} }}
</style>
<script>{plotly_js}</script>
</head>
<body>
<div class="app">
<aside>
<h1>Poverty, Informality, and Social Protection</h1>
<div class="small">Internal analytical dashboard for LAC country-year monitoring. Built from the reproducible repository pipeline.</div>
<nav>
<a href="#overview">Overview</a>
<a href="#map-section">Vulnerability Map</a>
<a href="#country-section">Country Profile</a>
<a href="#bolivia-section">Bolivia Lens</a>
<a href="#methods">Methods</a>
</nav>
<div class="small">Preferred window: 2000-2023<br/>Unit: country-year<br/>Status: pre-publication audit</div>
</aside>
<main>
<section id="overview" class="topbar">
<div class="title"><h2>Executive Monitoring View</h2><p>Track poverty, labor informality, social protection coverage, GDP, gender labor participation, inequality, and structural vulnerability across Latin America and the Caribbean.</p></div>
<div class="controls"><label>Country<select id="country"></select></label><label>Year<input id="year" type="range" min="2000" max="2023" value="2023" /></label><strong id="yearLabel">2023</strong></div>
</section>
<div class="summary" id="summaryText"></div>
<section class="kpis"><div class="kpi"><div class="label">Monetary poverty</div><div class="value" id="kpiPov">NA</div></div><div class="kpi"><div class="label">Labor informality</div><div class="value" id="kpiInf">NA</div></div><div class="kpi"><div class="label">Social protection</div><div class="value" id="kpiSP">NA</div></div><div class="kpi"><div class="label">Vulnerability index</div><div class="value" id="kpiVul">NA</div></div></section>
<section class="grid">
<div id="map-section" class="panel"><div id="map"></div></div>
<div class="panel"><div id="ranking"></div></div>
<div id="country-section" class="panel"><div id="trend"></div></div>
<div class="panel"><div id="profile"></div></div>
<div id="bolivia-section" class="panel wide"><div id="bolivia"></div></div>
</section>
<section id="methods" class="note">Method note: the dashboard uses the processed panel from the repository, not raw microdata. Values are descriptive and should not be read causally. The structural vulnerability index averages standardized poverty, informality, unemployment, inequality, low social protection, and low GDP per capita. Missingness reflects source coverage constraints.</section>
</main>
</div>
<script>
const data = {json.dumps(records)};
const fmt = x => (x === null || x === undefined || Number.isNaN(Number(x))) ? 'NA' : Number(x).toFixed(1);
const countries = [...new Set(data.map(d => d.country_name))].filter(Boolean).sort();
const select = document.getElementById('country');
countries.forEach(c => {{ const o=document.createElement('option'); o.value=c; o.textContent=c; select.appendChild(o); }});
select.value = countries.includes('Bolivia') ? 'Bolivia' : countries[0];
const palette = {{idb:'#005A8B', orange:'#F58518', green:'#54A24B', gray:'#486581', red:'#C0362C'}};
function average(rows, field) {{ const vals = rows.map(d=>d[field]).filter(v=>v!==null && v!==undefined && !Number.isNaN(Number(v))); return vals.length ? vals.reduce((a,b)=>a+Number(b),0)/vals.length : null; }}
function byYearAverage(field) {{ const y = {{}}; data.forEach(d=>{{ if(!y[d.year]) y[d.year]=[]; y[d.year].push(d); }}); return Object.entries(y).map(([year, rows])=>({{year:+year, value:average(rows, field)}})).filter(d=>d.value!==null).sort((a,b)=>a.year-b.year); }}
function update() {{
 const year = +document.getElementById('year').value; document.getElementById('yearLabel').textContent = year;
 const country = select.value; const rowsYear = data.filter(d=>d.year===year); const countryRows = data.filter(d=>d.country_name===country).sort((a,b)=>a.year-b.year); const row = rowsYear.find(d=>d.country_name===country) || countryRows[countryRows.length-1] || {{}};
 document.getElementById('kpiPov').textContent = fmt(row.monetary_poverty); document.getElementById('kpiInf').textContent = fmt(row.labor_informality); document.getElementById('kpiSP').textContent = fmt(row.social_protection_coverage); document.getElementById('kpiVul').textContent = fmt(row.structural_vulnerability_index);
 const lacPov = average(rowsYear, 'monetary_poverty'); const lacInf = average(rowsYear, 'labor_informality'); const lacSP = average(rowsYear, 'social_protection_coverage');
 document.getElementById('summaryText').innerHTML = `<strong>${{country}}</strong> in ${{year}}: poverty ${{fmt(row.monetary_poverty)}}%, informality ${{fmt(row.labor_informality)}}%, and social protection coverage ${{fmt(row.social_protection_coverage)}}%. LAC averages that year: poverty ${{fmt(lacPov)}}%, informality ${{fmt(lacInf)}}%, social protection ${{fmt(lacSP)}}%.`;
 Plotly.react('map', [{{type:'choropleth', locations:rowsYear.map(d=>d.iso3), z:rowsYear.map(d=>d.structural_vulnerability_index), text:rowsYear.map(d=>d.country_name), hovertemplate:'%{{text}}<br>Vulnerability: %{{z:.2f}}<extra></extra>', colorscale:'RdYlGn', reversescale:true, colorbar:{{title:'Index'}}}}], {{title:'Structural vulnerability map', geo:{{scope:'south america', showcountries:true, showframe:false}}, margin:{{t:46,l:0,r:0,b:0}}}}, {{responsive:true}});
 const rank = rowsYear.filter(d=>d.structural_vulnerability_index!==null).sort((a,b)=>b.structural_vulnerability_index-a.structural_vulnerability_index).slice(0,12).reverse();
 Plotly.react('ranking', [{{type:'bar', orientation:'h', y:rank.map(d=>d.country_name), x:rank.map(d=>d.structural_vulnerability_index), marker:{{color:palette.idb}}}}], {{title:'Highest vulnerability countries', xaxis:{{title:'Index'}}, margin:{{t:46,l:120,r:20,b:50}}}}, {{responsive:true}});
 const lacPoverty = byYearAverage('monetary_poverty');
 Plotly.react('trend', [{{x:countryRows.map(d=>d.year), y:countryRows.map(d=>d.monetary_poverty), mode:'lines+markers', name:country, line:{{color:palette.idb, width:3}}}}, {{x:lacPoverty.map(d=>d.year), y:lacPoverty.map(d=>d.value), mode:'lines', name:'LAC average', line:{{color:palette.gray, dash:'dot', width:2}}}}], {{title:'Poverty trend', yaxis:{{title:'Percent'}}, margin:{{t:46,l:55,r:20,b:45}}}}, {{responsive:true}});
 Plotly.react('profile', [{{type:'bar', x:['Poverty','Informality','Social protection','Unemployment','Gini'], y:[row.monetary_poverty,row.labor_informality,row.social_protection_coverage,row.unemployment,row.gini], marker:{{color:[palette.idb,palette.orange,palette.green,palette.red,palette.gray]}}}}], {{title:'Country profile', yaxis:{{title:'Percent / index'}}, margin:{{t:46,l:55,r:20,b:70}}}}, {{responsive:true}});
 const bol = data.filter(d=>d.country_name==='Bolivia').sort((a,b)=>a.year-b.year);
 Plotly.react('bolivia', [{{x:bol.map(d=>d.year), y:bol.map(d=>d.monetary_poverty), mode:'lines+markers', name:'Poverty', line:{{color:palette.idb,width:3}}}}, {{x:bol.map(d=>d.year), y:bol.map(d=>d.labor_informality), mode:'lines+markers', name:'Informality', line:{{color:palette.orange,width:3}}}}, {{x:bol.map(d=>d.year), y:bol.map(d=>d.social_protection_coverage), mode:'lines+markers', name:'Social protection', line:{{color:palette.green,width:3}}}}], {{title:'Bolivia profile: poverty, informality, and protection', yaxis:{{title:'Percent'}}, margin:{{t:46,l:55,r:20,b:45}}, legend:{{orientation:'h'}}}}, {{responsive:true}});
}}
select.addEventListener('change', update); document.getElementById('year').addEventListener('input', update); update();
</script>
</body>
</html>
"""
    (DASHBOARD_DIR / "index.html").write_text(html, encoding="utf-8")


def main() -> int:
    panel = load_data()
    build_preview(panel)
    build_html(panel)
    print("dashboard_built")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
