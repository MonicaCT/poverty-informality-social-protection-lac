# Dashboard Documentation

The dashboard is a self-contained HTML file. On GitHub Pages it is served at [dashboard/](dashboard/), and in the repository source it is available at `dashboard/index.html`. It embeds Plotly.js and the processed panel so it can be opened offline.

## Screenshots

![Dashboard overview](assets/screenshots/dashboard-overview.png)

![Country profile](assets/screenshots/dashboard-country-profile.png)

![Mobile layout](assets/screenshots/dashboard-mobile.png)

## Rebuild

```bash
python code/python/03_build_dashboard.py
```

The script also writes `dashboard/dashboard_panel.csv` and `dashboard/dashboard_preview.png`.

