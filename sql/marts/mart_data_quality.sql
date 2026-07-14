-- Data quality mart for future Tableau QA page.

SELECT
    quality_check_key,
    iso3,
    year,
    variable,
    missingness_rate,
    duplicate_country_year_rows,
    impossible_percent_values,
    status,
    notes
FROM fact_data_quality;
