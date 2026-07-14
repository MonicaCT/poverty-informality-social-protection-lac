# Interaction Specifications

## Global Filters

- Country filter from `dim_country[country_name]`.
- Region filter from `dim_country[region_lac]`.
- Year range filter from `dim_time[year]`.
- Metric Selector parameter for metric-switching views.
- Data Quality Threshold parameter for missingness warnings.

## Actions

- Filter action from country ranking to detail panels.
- Highlight action from region selection to country marks.
- Parameter action for Metric Selector where supported.
- Navigation buttons between the five dashboards and the story.
- Reset Filters button using a default-state dashboard action or worksheet instruction.

## Drill-Down

Allowed: region to country and country to year trend.

Not allowed: raw records, household data or source-file paths.

## Dynamic Zone Visibility

Optional. Use only if it simplifies the metric selector and does not hide warnings.
